module XPrint
    @data_classes = [
        String, Integer, Float, TrueClass, FalseClass, NilClass,
        Symbol
    ]
    @hash_name_classes = @data_classes + [Proc]
    @tab = "\t"
    @show_indexes = true
    @full_proc_path = false
    @braces = true

    def self.set(**kwargs)
        set_vars = {
            tab:            ->(data) { @tab            = data },
            show_indexes:   ->(data) { @show_indexes   = data },
            full_proc_path: ->(data) { @full_proc_path = data },
            braces:         ->(data) { @braces         = data }
        }
    
        kwargs.each do |keyword, arg|
            if set_vars.key? keyword
                set_vars[keyword].(arg)
            end
        end
    
        return
    end

    def self.tab()
        @tab
    end

    def self.show_indexes()
        @show_indexes
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
        if @data_classes.include? x.class
            return x.inspect
        # X is a Proc, print more compact version of standard Proc.inspect
        # text.
        elsif x.class == Proc
            type = x.lambda? ? 'Lambda' : 'Proc'
            source, line = x.source_location
            source = source.gsub('\\', '/')
            
            unless @full_proc_path
                source = source.split('/')[-2..-1].join('/')
            end
            
            return "<#{type} @ #{source} [Line #{line}]>"
        # X is an Array, print list of all items.
        elsif x.class == Class
            return "<Class #{x}>"
        elsif x.class == Array
            result = "#{@braces ? '[' : ''}\n"
    
            x.each_with_index do |item, index|
                data = xpand(item, indent: _indent, tab: tab)
                
                result += "#{_indent}"
                result += "[#{index}] " if @show_indexes
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
                    result += ", \n"
                end
            end

            result += "\n#{indent}}" if @braces
    
            return result
        # X is a Structure; essentially a special case of X being an object.
        elsif x.is_a? Struct
            result = "Struct #{x.class}#{@braces ? '(' : ''}\n"
            longest_item = x.members.map { |m| m.to_s.length }.max()

            x.each_pair do |name, value|
                attr_name = name.to_s.ljust(longest_item)
                attr_data = xpand(value, indent: _indent, tab: tab)

                result += "#{_indent}#{attr_name} = #{attr_data}\n"
            end

            result += "#{indent})" if @braces

            return result
        # X is any arbitrary object; print all instance variables.
        else
            classname = x.class == Module ? "Module #{x}" : x.class
            result = "#{classname}#{@braces ? '(' : ''}"
            ivars = x.instance_variables
            result += "\n" if ivars.length > 0
            longest_var = ivars.map { |v| v.to_s.length }.max()
    
            ivars.each_with_index do |var, index|
                attr_name = var.to_s.ljust(longest_var)
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
