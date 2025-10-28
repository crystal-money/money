{% skip_file unless @top_level.has_constant?(:JSON) %}

require "big/json"
require "uri/json"

class Money::Currency
  include JSON::Serializable

  def self.new(pull : JSON::PullParser)
    if pull.kind.string?
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
  end

  class Exchange
    include JSON::Serializable
  end
end
