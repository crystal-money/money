require "json"

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

  struct Rate
    include JSON::Serializable

    def to_json(json : JSON::Builder)
      json.object do
        json.field "from", from.to_s
        json.field "to", to.to_s
        json.field "value", value
      end
    end
  end
end
