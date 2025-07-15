require "json"
require "big/json"
require "uri/json"

class Money::Currency
  include JSON::Serializable

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when .string?
      find(pull.read_string)
    else
      previous_def
    end
  end

  # :nodoc:
  def self.from_json_object_key?(value : String) : Currency
    find(value)
  end

  # :nodoc:
  def to_json_object_key : String
    to_s
  end

  struct Rate
    include JSON::Serializable

    def to_json(json : JSON::Builder)
      {
        base:       base.to_s,
        target:     target.to_s,
        value:      value,
        updated_at: updated_at,
      }.to_json(json)
    end
  end

  module RateProvider::Converter
    private struct JSONWrapper
      include JSON::Serializable

      getter name : String
      getter options : Hash(String, JSON::Any::Type)?
    end

    def self.from_json(pull : JSON::PullParser) : RateProvider
      wrapper = JSONWrapper.new(pull)

      klass =
        RateProvider.find(wrapper.name)

      if options = wrapper.options
        klass.from_json(options.to_json)
      else
        klass.from_json("{}")
      end
    end

    def self.to_json(provider : RateProvider, json : JSON::Builder)
      {
        name:    provider.class.key,
        options: provider,
      }.to_json(json)
    end
  end
end
