{% skip_file unless @top_level.has_constant?(:JSON) %}

struct Money
  module Registry::Converter::JSON(V)
    private struct Wrapper(T)
      include ::JSON::Serializable

      getter name : String
      getter options : Hash(String, ::JSON::Any::Type)?

      def unbox : T
        klass = T.find(name)
        klass.from_json(options.try(&.to_json) || "{}")
      end
    end

    extend self

    def from_json(pull : ::JSON::PullParser) : V
      wrapper = Wrapper(V).new(pull)
      wrapper.unbox
    end

    def to_json(value : V, json : ::JSON::Builder)
      {
        name:    value.class.key,
        options: value,
      }.to_json(json)
    end
  end
end
