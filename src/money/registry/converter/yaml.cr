{% skip_file unless @top_level.has_constant?(:YAML) %}

struct Money
  module Registry::Converter::YAML(V)
    private struct Wrapper
      include ::YAML::Serializable

      getter! name : String
      getter options : Hash(String, ::YAML::Any::Type)?
    end

    extend self

    def from_yaml(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node) : V
      wrapper = Wrapper.new(ctx, node)

      klass =
        V.find(wrapper.name)

      if options = wrapper.options
        klass.from_yaml(options.to_yaml)
      else
        klass.from_yaml("{}")
      end
    end

    def to_yaml(value : V, yaml : ::YAML::Nodes::Builder)
      {
        name:    value.class.key,
        options: value,
      }.to_yaml(yaml)
    end
  end
end
