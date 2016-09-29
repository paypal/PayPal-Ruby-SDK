module PayPal
  module SDK
    module REST
      class ErrorHash < Core::Util::OrderedHash
        def self.convert(hash)
          error_hash = new
          hash.each { |key, value|
            error_hash[key] = value
          }
          error_hash
        end

        def []=(key, value)
          value =
              if value.is_a? Hash
                ErrorHash.convert(hash)
              elsif value.is_a? Array and value[0].is_a? Hash
                value.map { |array_value| ErrorHash.convert(array_value) }
              else
                value
              end
          super(key, value)
        end

        def [](name)
          super(name.to_s) || super(name.to_sym)
        end

        def method_missing(name, *args)
          if keys.include?(name) or keys.include?(name.to_s)
            self[name]
          else
            super
          end
        end
      end
    end
  end
end
