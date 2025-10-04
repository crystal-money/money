{% skip_file unless @top_level.has_constant?(:YAML) %}

struct Money
  module Registry::Converter::YAML(V)
    private struct Wrapper(T)
      include ::YAML::Serializable

      getter! name : String
      getter options : Hash(String, ::YAML::Any::Type)?

      def unbox : T
        klass = T.find(name)
        klass.from_yaml(options.try(&.to_yaml) || "{}")
      end
    end

    extend self

    def from_yaml(ctx : ::YAML::ParseContext, node : ::YAML::Nodes::Node) : V
      wrapper = Wrapper(V).new(ctx, node)
      wrapper.unbox
    end

    def to_yaml(value : V, yaml : ::YAML::Nodes::Builder)
      {
        name:    value.class.key,
        options: value,
      }.to_yaml(yaml)
    end
  end
end
