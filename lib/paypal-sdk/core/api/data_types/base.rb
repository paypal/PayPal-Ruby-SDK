require 'date'

module PayPal::SDK::Core
  module API

    module DataTypes

      # Create attributes and restrict the object type.
      # == Example
      #   class ConvertCurrencyRequest < Core::API::DataTypes::Base
      #     object_of :baseAmountList,        CurrencyList
      #     object_of :convertToCurrencyList, CurrencyCodeList
      #     object_of :countryCode,           String
      #     object_of :conversionType,        String
      #   end
      class Base

        HashOptions = {:attribute => true, :namespace => true, :symbol => false}
        ContentKey = :value

        include SimpleTypes
        include Logging

        class << self

          # Add attribute
          # === Arguments
          # * <tt>name</tt>  -- attribute name
          # * <tt>options</tt> -- options
          def add_attribute(name, options = {})
            add_member(name, SimpleTypes::String, options.merge(:attribute => true))
          end

          # Fields list for the DataTye
          def members
            @members ||=
                begin
                  superclass.load_members if defined? superclass.load_members
                  parent_members = superclass.instance_variable_get("@members")
                  parent_members ? parent_members.dup : Util::OrderedHash.new
                end
          end

          # Add Field to class variable hash and generate methods
          # === Example
          #   add_member(:errorMessage, String)  # Generate Code
          #   # attr_reader   :errorMessage
          #   # alias_method  :error_message,  :errorMessage
          #   # alias_method  :error_message=, :errorMessage=
          def add_member(member_name, klass, options = {})
            member_name = member_name.to_sym
            return if members[member_name]
            members[member_name] = options.merge(:type => klass)
            member_variable_name = "@#{member_name}"
            define_method "#{member_name}=" do |value|
              object = options[:array] ? convert_array(value, klass) : convert_object(value, klass)
              instance_variable_set(member_variable_name, object)
            end
            default_value = (options[:array] ? [] : (klass < Base ? Util::OrderedHash.new : nil))
            define_method member_name do |&block|
              value = instance_variable_get(member_variable_name) || (default_value && send("#{member_name}=", default_value))
              value.instance_eval(&block) if block
              value
            end
            define_alias_methods(member_name, options)
          end

          # Define alias methods for getter and setter
          def define_alias_methods(member_name, options)
            snakecase_name = snakecase(member_name)
            alias_method snakecase_name, member_name
            alias_method "#{snakecase_name}=", "#{member_name}="
            alias_method "#{options[:namespace]}:#{member_name}=", "#{member_name}=" if options[:namespace]
            if options[:attribute]
              alias_method "@#{member_name}=", "#{member_name}="
              alias_method "@#{options[:namespace]}:#{member_name}=", "#{member_name}=" if options[:namespace]
            end
          end

          # define method for given member and the class name
          # === Example
          #   object_of(:errorMessage, ErrorMessage) # Generate Code
          #   # def errorMessage=(options)
          #   #   @errorMessage = ErrorMessage.new(options)
          #   # end
          #   # add_member :errorMessage, ErrorMessage
          def object_of(key, klass, options = {})
            add_member(key, klass, options)
          end

          # define method for given member and the class name
          # === Example
          #   array_of(:errorMessage, ErrorMessage) # It Generate below code
          #   # def errorMessage=(array)
          #   #   @errorMessage = array.map{|options| ErrorMessage.new(options) }
          #   # end
          #   # add_member :errorMessage, ErrorMessage
          def array_of(key, klass, options = {})
            add_member(key, klass, options.merge(:array => true))
          end

          # Generate snakecase string.
          # === Example
          # snakecase("errorMessage")
          # # error_message
          def snakecase(string)
            string.to_s.gsub(/([a-z])([A-Z])/, '\1_\2').gsub(/([A-Z])([A-Z][a-z])/, '\1_\2').downcase
          end

        end

        # Initialize options.
        def initialize(options = {}, &block)
          merge!(options, &block)
        end

        # Merge values
        def merge!(options, &block)
          if options.is_a? Hash
            options.each do |key, value|
              set(key, value)
            end
          elsif members[ContentKey]
            set(ContentKey, options)
          else
            raise ArgumentError, "invalid data(#{options.inspect}) for #{self.class.name} class"
          end
          self.instance_eval(&block) if block
          self
        end

        # Set value for given member
        # === Arguments
        # * <tt>key</tt> -- member name
        # * <tt>value</tt> -- value for member
        def set(key, value)
          send("#{key}=", value)
        rescue NoMethodError => error
          logger.warn error.message
        rescue TypeError, ArgumentError => error
          raise TypeError, "#{error.message}(#{value.inspect}) for #{self.class.name}.#{key} member"
        end

        # Create array of objects.
        # === Example
        # covert_array([{ :amount => "55", :code => "USD"}], CurrencyType)
        # covert_array({ "0" => { :amount => "55", :code => "USD"} }, CurrencyType)
        # covert_array({ :amount => "55", :code => "USD"}, CurrencyType)
        # # @return
        # # [ <CurrencyType#object @amount="55" @code="USD" > ]
        def convert_array(array, klass)
          default_value = (klass < Base ? Util::OrderedHash.new : nil)
          data_type_array = ArrayWithBlock.new { |object| convert_object(object || default_value, klass) }
          data_type_array.merge!(array)
        end

        # Create object based on given data.
        # === Example
        # covert_object({ :amount => "55", :code => "USD"}, CurrencyType )
        # # @return
        # # <CurrencyType#object @amount="55" @code="USD" >
        def convert_object(object, klass)
          object.is_a?(klass) ? object : ((object.nil? or object == "") ? nil : klass.new(object))
        end

        # Alias instance method for the class method.
        def members
          self.class.members
        end

        # Get configured member names
        def member_names
          members.keys
        end

        # Create Hash based configured members
        def to_hash(options = {})
          options = HashOptions.merge(options)
          hash = Util::OrderedHash.new
          member_names.each do |member|
            value = value_to_hash(instance_variable_get("@#{member}"), options)
            hash[hash_key(member, options)] = value unless skip_value?(value)
          end
          hash
        end

        # Skip nil, empty array and empty hash.
        def skip_value?(value)
          value.nil? || ((value.is_a?(Array) || value.is_a?(Hash)) && value.empty?)
        end

        # Generate Hash key for given member name based on configuration
        # === Example
        # hash_key(:amount) # @return :"ebl:amount"
        # hash_key(:type)   # @return :"@type"
        def hash_key(key, options = {})
          unless key == ContentKey
            member_option = members[key]
            key = member_option[:name] if member_option.include? :name
            if !member_option[:attribute] and member_option[:namespace] and options[:namespace]
              key = "#{member_option[:namespace]}:#{key}"
            end
            key = "@#{key}" if member_option[:attribute] and options[:attribute]
          end
          options[:symbol] ? key.to_sym : key.to_s
        end

        # Covert the object to hash based on class.
        def value_to_hash(value, options = {})
          case value
            when Array
              value = value.map { |object| value_to_hash(object, options) }
              value.delete_if { |v| skip_value?(v) }
              value
            when Base
              value.to_hash(options)
            else
              value
          end
        end
      end
    end
  end
end
