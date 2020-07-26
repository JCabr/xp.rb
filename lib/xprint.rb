require 'bigdecimal'
require 'date'
require 'yaml'

# TODO: Add ability for alphabetically sorting
#       items in hashes and objects.
module XPrint
    @data_classes      = [
        String, Integer, Float, TrueClass, FalseClass, NilClass,
        Symbol, Date, Time, DateTime, BigDecimal, Rational
    ]
    @hash_name_classes = @data_classes + [Proc]
    @tab               = "  "
    @indexes           = true
    @full_proc_path    = false
    @braces            = true
    @date_format       = '%F'
    @time_format       = '%c'
    @datetime_format   = '%FT%T%:z'
    @hash_separator    = ' => '
    @commas            = true
    @color             = true
    @colors            = {
        attribute:      :blue,
        bigdecimal:     :darkcyan,
        classname:      :darkgreen,
        classobject:    :green,
        comma:          :default,
        curly_brace:    :default,
        date:           :red,
        datetime:       :purple,
        equals:         :default,
        false:          :darkred,
        float:          :cyan,
        hash_separator: :default,
        index:          :darkgrey,
        integer:        :cyan,
        module:         :green,
        nil:            :darkpurple,
        parentheses:    :default,
        proc:           :darkyellow,
        rational:       :darkcyan,
        string:         :yellow,
        struct:         :green,
        square_brace:   :default,
        symbol:         :darkblue,
        time:           :darkblue,
        true:           :darkgreen
    }
    @color_codes       = {
        black:      "\e[30m",
        blue:       "\e[94m",
        darkblue:   "\e[34m",
        cyan:       "\e[96m",
        darkcyan:   "\e[36m",
        green:      "\e[92m",
        darkgreen:  "\e[32m",
        grey:       "\e[37m",
        darkgrey:   "\e[90m",
        red:        "\e[91m",
        darkred:    "\e[31m",
        purple:     "\e[95m",
        darkpurple: "\e[35m",
        yellow:     "\e[93m",
        darkyellow: "\e[33m",
        default:    "\e[0m"
    }

    def self.set(**kwargs)
        kwargs.each do |keyword, arg|
            self.instance_variable_set "@#{keyword}", arg
        end
    
        return
    end

    def self.load_file(config)
        config_data = YAML.load( File.read config )
        config_data = self.symbolize_keys(config_data)

        if config_data.key? :general
            self.set **config_data[:general]
        end

        if config_data.key? :colors
            color_data = config_data[:colors]

            color_data.each do |name, color|
                color_data[name] = color.to_sym
            end

            self.set_color_for **config_data[:colors]
        end

        if config_data.key? :'color codes'
            self.set_color_code_for **config_data[:'color codes']
        end
    end

    def self.load(config)
        calling_file = caller_locations.first.absolute_path
        base_dir = File.dirname calling_file
        relative_config = File.expand_path config, base_dir

        self.load_file relative_config
    end

    private_class_method def self.symbolize_keys(hash)
        hash.inject({}) do |result, (key, value)|
            new_key = key.to_sym
            new_value = value.is_a?(Hash) ? symbolize_keys(value) : value

            result[new_key] = new_value
            
            result
        end
    end

    def self.set_color_for(**kwargs)
        kwargs.each do |keyword, arg|
            @colors[keyword] = arg
        end
    end

    def self.set_color_code_for(**kwargs)
        kwargs.each do |keyword, arg|
            @color_codes[keyword] = arg
        end
    end

    def self.xp(*args)
        args.each do |arg|
            xpanded_text = self.xpand(arg, tab: @tab)

            unless @braces
                xpanded_text = self.shift_indentation_down(xpanded_text).lstrip()
            end

            puts xpanded_text
        end
    end

    private_class_method def self.color_for(colorname)
        @color_codes[colorname]
    end

    private_class_method def self.reset_color()
        @color_codes[:default]
    end

    private_class_method def self.colorize(text, type)
        if @color
            item_color = color_for @colors[type]
            "#{item_color}#{text}#{reset_color}"
        else
            text
        end
    end

    private_class_method def self.shift_indentation_down(text)
        # Only shift if no 
        return text if text.match?(/^\S/)
        result = ''

        text.each_line do |line|
            result += (
                if line.start_with? @tab
                    line[@tab.length..-1]
                else
                    line
                end
            )
        end

        return result
    end

    def self.xpand(x, indent: '', tab: '  ')

        _indent = "#{tab}#{indent}"

        # X is a "primitive" kind of data that has no subitems, so
        # we can just print it.
        if x.class == String
            return colorize(x.inspect, :string)
        elsif x.class == Integer
            return colorize(x.inspect, :integer)
        elsif x.class == Float
            return colorize(x.inspect, :float)
        elsif x.class == TrueClass
            return colorize(x.inspect, :true)
        elsif x.class == FalseClass
            return colorize(x.inspect, :false)
        elsif x.class == NilClass
            return colorize(x.inspect, :nil)
        elsif x.class == Symbol
            return colorize(x.inspect, :symbol)
        
        # X is a Proc, print more compact version of standard Proc.inspect
        # text.
        elsif x.class == Proc
            type = x.lambda? ? 'Lambda' : 'Proc'
            source, line = x.source_location
            source = source.gsub('\\', '/')
            
            unless @full_proc_path
                source = source.split('/')[-2..-1].join('/')
            end
            
            return colorize("<#{type} @ #{source} [Line #{line}]>", :proc)
        
        elsif x.class == Class
            return colorize("<Class #{x}>", :classobject)
        
        # X is an Array, print list of all items.
        elsif x.class == Array
            result = "#{@braces ? colorize('[', :square_brace) : ''}\n"
            comma = colorize(',', :comma)
    
            x.each_with_index do |item, index|
                data = xpand(item, indent: _indent, tab: tab)
                
                result += "#{_indent}"
                if @indexes
                    adjustment = x.length.to_s.length + 3
                    # Account for characters used for color coding.
                    adjustment += 9 if @color

                    result += "#{colorize("[#{index}]", :index)} ".
                                ljust(adjustment)
                end
                result += "#{data}"
    
                unless index + 1 == x.length
                    show_commas = @commas && @braces

                    result += "#{show_commas ? "#{comma}" : ''}"
                    result += "\n" unless result.end_with? "\n"
                end
            end
    
            result += "\n#{indent}#{colorize(']', :square_brace)}" if @braces
            return result
        
        # X is a Hash, print all keys and values.
        elsif x.class == Hash
            comma = colorize(',', :comma)
            result = "#{@braces ? colorize('{', :curly_brace) : ''}\n"

            longest_key = (
                x.keys.filter do |k, v|
                    @hash_name_classes.include? k.class
                end.
                map do |k, v| 
                    k.to_s.length 
                end.
                max()
            )

            longest_key = 0 if longest_key.nil?

            # Color codes throw the text length, so we need to add the
            # length of the color code and the code to reset the color
            # that wrap around the colored word.
            # The color code is like "\e[99m" and the reset "\e[0m",
            # so the total length to add when using color is 9.
            longest_key += 9 if @color
    
            x.each_with_index do |(key, value), index|
                data_key   = "#{xpand(key, indent: _indent, tab: tab)}"

                data_key = (
                    if @hash_name_classes.include? key.class
                        data_key.ljust(longest_key + 1)
                    else
                        data_key.ljust(data_key.length + longest_key)
                    end
                )

                data_value = xpand(value, indent: _indent, tab: tab)

                hash_separator = colorize(@hash_separator, :hash_separator)
                result += "#{_indent}#{data_key}#{hash_separator}#{data_value}"

                unless index + 1 == x.length
                    show_commas = @commas && @braces
                    result += "#{show_commas ? "#{comma} " : ''}"
                    result += "\n" unless result.end_with? "\n"
                end
            end

            result += "\n#{indent}#{colorize('}', :curly_brace)}" if @braces
    
            return result

        # X is a commonly used special kind of object.
        elsif x.class == DateTime
            datetime = x.strftime @datetime_format
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)
            return colorize("DateTime#{p1}#{datetime}#{p2}", :datetime)
        
        elsif x.class == Date
            date = x.strftime @date_format
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)
            return colorize("Date#{p1}#{date}#{p2}", :date)
        
        elsif x.class == Time
            time = x.strftime @time_format
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)
            return colorize("Time#{p1}#{time}#{p2}", :time)
        
        elsif x.class == BigDecimal
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)
            return colorize("BigDecimal#{p1}#{x.to_s('f')}#{p2}", :bigdecimal)
        
        elsif x.class == Rational
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)
            return colorize("Rational#{p1}#{x}#{p2}", :rational)
        
        # X is a Structure; essentially a special case of X being an object.
        elsif x.is_a? Struct
            struct_word = colorize('Struct', :struct)
            classname = colorize(x.class, :struct)
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)
            result = "#{struct_word} #{classname}#{@braces ? p1 : ''}\n"
            longest_item = x.members.map { |m| m.to_s.length }.max()
            eq_sign = colorize('=', :equals)

            x.each_pair do |name, value|
                attr_name = colorize(name.to_s.ljust(longest_item), :attribute)
                attr_data = xpand(value, indent: _indent, tab: tab)

                result += "#{_indent}#{attr_name} #{eq_sign} #{attr_data}"
                result += "\n" unless result.end_with? "\n"
            end

            result += "#{indent}#{p2}" if @braces

            return result
        
        # X is any arbitrary object; print all instance variables.
        else
            p1 = colorize('(', :parentheses)
            p2 = colorize(')', :parentheses)

            is_module = x.class == Module
            classname = is_module ? "Module #{x}" : x.class
            classname = colorize(classname, is_module ? :module : :classname)
            result = "#{classname}#{@braces ? p1 : ''}"
            ivars = x.instance_variables
            result += "\n" if ivars.length > 0
            longest_var = ivars.map { |v| v.to_s.length }.max()
            eq_sign = colorize('=', :equals)
    
            ivars.each_with_index do |var, index|
                attr_name = var.to_s.ljust(longest_var)
                attr_name = colorize(attr_name, :attribute)
                attr_data = xpand(
                    x.instance_variable_get(var),
                    indent: _indent,
                    tab: tab
                )

                result += "#{_indent}#{attr_name} #{eq_sign} #{attr_data}"
                result += "\n" unless result.end_with? "\n"
            end
    
            result += "#{ivars.length > 0 ? indent: ''}#{p2}" if @braces
    
            return result
        end
    end    
end

def xp(*args)
    XPrint::xp(*args)
end

def xpand(item, tab: "\t")
    XPrint::xpand(item, tab: tab)
end
