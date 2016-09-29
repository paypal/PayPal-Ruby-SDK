require 'date'

module PayPal::SDK::Core
  module API
    module DataTypes

      module SimpleTypes
        class String < ::String
          def self.new(string = "")
            string.is_a?(::String) ? super : super(string.to_s)
          end

          def to_yaml_type
            "!tag:yaml.org,2002:str"
          end
        end

        class Integer < ::Integer
          def self.new(number)
            number.to_i
          end
        end

        class Float < ::Float
          def self.new(float)
            float.to_f
          end
        end

        class Boolean
          def self.new(boolean)
            (boolean == 0 || boolean == "" || boolean =~ /^(false|f|no|n|0)$/i) ? false : !!boolean
          end
        end

        class Date < ::Date
          def self.new(date)
            date.is_a?(::Date) ? date : Date.parse(date.to_s)
          end
        end

        class DateTime < ::DateTime
          def self.new(date_time)
            date_time = "0001-01-01T00:00:00" if date_time.to_s == "0"
            date_time.is_a?(::DateTime) ? date_time : parse(date_time.to_s)
          end
        end
      end

    end
  end
end
