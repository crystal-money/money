require "big/json"
require "json"

struct BigDecimal
  def to_json(json : JSON::Builder)
    json.string(to_s)
  end
end

struct Money
  JSON.mapping({
    amount:   {type: BigDecimal, setter: false},
    currency: {type: Currency, setter: false},
  })

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when .string?
      parse(pull.read_string)
    else
      previous_def
    end
  end
end
