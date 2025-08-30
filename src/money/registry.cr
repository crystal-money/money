struct Money
  module Registry
    # Raised when trying to find an unknown object.
    class NotFoundError < Error
      def initialize(key)
        super("Object not found: #{key}")
      end
    end

    macro extended
      Money::Registry.setup {{ @type }}
      Money::Registry.setup_serializable {{ @type }}
    end

    macro setup(klass)
      # All registered objects.
      class_getter registry = {} of String => {{ klass }}.class

      macro inherited
        \{% @type.raise "abstract descendants are not allowed" if @type.abstract? %}
        {{ %({% base_namespace = #{klass}.id %}).id }}
        \{%
          name = @type.name
          name =
            if name.starts_with?("#{base_namespace}::")
              name[base_namespace.size + 2..].underscore
            else
              @type.raise "class #{@type} must be placed inside #{base_namespace} namespace"
            end
        \%}
        \{{ base_namespace }}.registry[\{{ name.stringify }}] = self

        # Returns the class key.
        def self.key : String
          \{{ name.stringify }}
        end
      end

      # Returns the `{{ klass }}.class` for the given *name* if found,
      # `nil` otherwise.
      def self.find?(name : String | Symbol) : {{ klass }}.class | Nil
        registry[name.to_s.underscore]?
      end

      # Returns the `{{ klass }}.class` for the given *name* if found,
      # raises `Registry::NotFoundError` otherwise.
      def self.find(name : String | Symbol) : {{ klass }}.class
        find?(name) ||
          raise Registry::NotFoundError.new(name)
      end
    end

    macro setup_serializable(klass)
      if_defined?(:JSON) do
        module Converter
          extend Money::Converter::JSON({{ klass }})
        end

        include JSON::Serializable

        # Alias of `Converter.from_json`.
        def self.new(pull : JSON::PullParser)
          Converter.from_json(pull)
        end
      end

      if_defined?(:YAML) do
        module Converter
          extend Money::Converter::YAML({{ klass }})
        end

        include YAML::Serializable

        # Alias of `Converter.from_yaml`.
        def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
          Converter.from_yaml(ctx, node)
        end
      end
    end
  end
end
