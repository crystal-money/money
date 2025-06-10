module Money::Mixin
  # Maps passed *attributes* to `@ivar_variables` and `self.property_setters=`.
  #
  # NOTE: Magic inside!
  module InitializeWith
    def initialize_with(attributes)
      {% begin %}
        {%
          properties = @type.methods
            .select { |method| method.name.ends_with?('=') && method.args.size == 1 }
            .map(&.name[0...-1].symbolize)
            .uniq
        %}

        {% for name in properties %}
          if (
            arg =
              attributes[{{ name }}]? ||
                attributes[{{ name.id.stringify }}]?
          ).is_a?(typeof(self.{{ name.id }}))
            self.{{ name.id }} = arg
          end
        {% end %}

        {%
          ivars = @type.instance_vars
            .map(&.name.symbolize)
            .uniq
        %}

        {% for name in ivars %}
          {% unless properties.includes?(name) %}
            if (
              arg =
                attributes[{{ name }}]? ||
                  attributes[{{ name.id.stringify }}]?
            ).is_a?(typeof(@{{ name.id }}))
              @{{ name.id }} = arg
            end
          {% end %}
        {% end %}
      {% end %}

      self
    end

    def initialize_with(**attributes)
      initialize_with(attributes)
    end
  end
end
