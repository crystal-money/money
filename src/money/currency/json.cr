require "json"
require "big/json"

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
      json.object do
        json.field "base", base.to_s
        json.field "target", target.to_s
        json.field "value", value
        json.field "updated_at", updated_at
      end
    end
  end
end
