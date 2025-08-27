{% skip_file unless @top_level.has_constant?(:JSON) %}

struct Money
  module Converter::JSON(V)
    private struct Wrapper
      include ::JSON::Serializable

      getter name : String
      getter options : Hash(String, ::JSON::Any::Type)?
    end

    extend self

    def from_json(pull : ::JSON::PullParser) : V
      wrapper = Wrapper.new(pull)

      klass =
        V.find(wrapper.name)

      if options = wrapper.options
        klass.from_json(options.to_json)
      else
        klass.from_json("{}")
      end
    end

    def to_json(value : V, json : ::JSON::Builder)
      {
        name:    value.class.key,
        options: value,
      }.to_json(json)
    end
  end
end
