module PayPal::SDK::Core
  module API
    module DataTypes
      # Create Array with block.
      # === Example
      #   ary = ArrayWithBlock.new{|val| val.to_i }
      #   ary.push("123") # [ 123 ]
      #   ary.merge!(["1", "3"])  # [ 123, 1, 3 ]
      class ArrayWithBlock < ::Array
        def initialize(&block)
          @block = block
          super()
        end

        def [](key)
          super(key) || send(:"[]=", key, nil)
        end

        def []=(key, value)
          super(key, @block ? @block.call(value) : value)
        end

        def push(value)
          super(@block ? @block.call(value) : value)
        end

        def merge!(array)
          if array.is_a? Array
            array.each do |object|
              push(object)
            end
          elsif array.is_a? Hash and array.keys.first.to_s =~ /^\d+$/
            array.each do |key, object|
              self[key.to_i] = object
            end
          else
            push(array)
          end
          self
        end
      end
    end
  end
end
