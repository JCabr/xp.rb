require 'bigdecimal'
require 'date'

module XPrint
    @data_classes = [
        String, Integer, Float, TrueClass, FalseClass, NilClass,
        Symbol, Date, Time, DateTime, BigDecimal, Rational
    ]
    @hash_name_classes = @data_classes + [Proc]
    @tab = "\t"
    @indexes = true
    @full_proc_path = false
    @braces = true
    @date_format = '%F'
    @time_format = '%c'
    @datetime_format = '%FT%T%:z'
    @color = false
    @colors = {
        attribute:   :blue,
        bigdecimal:  :darkcyan,
        classname:   :darkgreen,
        classobject: :green,
        date:        :red,
        datetime:    :purple,
        false:       :darkred,
        float:       :cyan,
        index:       :darkgrey,
        integer:     :cyan,
        module:      :green,
        nil:         :darkpurple,
        proc:        :darkyellow,
        rational:    :darkcyan,
        string:      :yellow,
        struct:      :green,
        symbol:      :darkblue,
        time:        :darkblue,
        true:        :darkgreen
    }
    @color_codes = {
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
        reset:      "\e[0m"
    }

    def self.set(**kwargs)
        set_vars = {
            tab:             ->(data) { @tab             = data },
            indexes:         ->(data) { @indexes         = data },
            full_proc_path:  ->(data) { @full_proc_path  = data },
            braces:          ->(data) { @braces          = data },
            date_format:     ->(data) { @date_format     = data },
            time_format:     ->(data) { @time_format     = data },
            datetime_format: ->(data) { @datetime_format = data },
            color:           ->(data) { @color           = data }
        }
    
        kwargs.each do |keyword, arg|
            if set_vars.key? keyword
                set_vars[keyword].(arg)
            end
        end
    
        return
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
        @color_codes[:reset]
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

    def self.xpand(x, indent: '', tab: "\t")

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
            result = "#{@braces ? '[' : ''}\n"
    
            x.each_with_index do |item, index|
                data = xpand(item, indent: _indent, tab: tab)
                
                result += "#{_indent}"
                result += "#{colorize("[#{index}]", :index)} " if @indexes
                result += "#{data}"
    
                unless index + 1 == x.length
                    result += "#{@braces ? ', ' : ''} \n"
                end
            end
    
            result += "\n#{indent}]" if @braces
            return result
        
        # X is a Hash, print all keys and values.
        elsif x.class == Hash
            result = "#{@braces ? '{' : ''}\n"

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

                result += "#{_indent}#{data_key} => #{data_value}"

                unless index + 1 == x.length
                    result += "#{@braces ? ', ' : ''} \n"
                end
            end

            result += "\n#{indent}}" if @braces
    
            return result

        # X is a commonly used special kind of object.
        elsif x.class == DateTime
            datetime = x.strftime @datetime_format
            return colorize("DateTime(#{datetime})", :datetime)
        
        elsif x.class == Date
            date = x.strftime @date_format
            return colorize("Date(#{date})", :date)
        
        elsif x.class == Time
            time = x.strftime @time_format
            return colorize("Time(#{time})", :time)
        
        elsif x.class == BigDecimal
            return colorize("BigDecimal(#{x.to_s('f')})", :bigdecimal)
        
        elsif x.class == Rational
            return colorize("Rational(#{x})", :rational)
        
        # X is a Structure; essentially a special case of X being an object.
        elsif x.is_a? Struct
            struct_word = colorize('Struct', :struct)
            classname = colorize(x.class, :struct)
            result = "#{struct_word} #{classname}#{@braces ? '(' : ''}\n"
            longest_item = x.members.map { |m| m.to_s.length }.max()

            x.each_pair do |name, value|
                attr_name = colorize(name.to_s.ljust(longest_item), :attribute)
                attr_data = xpand(value, indent: _indent, tab: tab)

                result += "#{_indent}#{attr_name} = #{attr_data}\n"
            end

            result += "#{indent})" if @braces

            return result
        
        # X is any arbitrary object; print all instance variables.
        else
            is_module = x.class == Module
            classname = is_module ? "Module #{x}" : x.class
            classname = colorize(classname, is_module ? :module : :classname)
            result = "#{classname}#{@braces ? '(' : ''}"
            ivars = x.instance_variables
            result += "\n" if ivars.length > 0
            longest_var = ivars.map { |v| v.to_s.length }.max()
    
            ivars.each_with_index do |var, index|
                attr_name = var.to_s.ljust(longest_var)
                attr_name = colorize(attr_name, :attribute)
                attr_data = xpand(
                    x.instance_variable_get(var),
                    indent: _indent,
                    tab: tab
                )

                result += "#{_indent}#{attr_name} = #{attr_data}\n"
            end
    
            result += "#{ivars.length > 0 ? indent: ''})" if @braces
    
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