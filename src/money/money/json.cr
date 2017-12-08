require "json"

class Money
  JSON.mapping({
    fractional: {type: Int64, setter: false},
    currency:   {type: Currency, setter: false},
  })

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when :string
      parse(pull.read_string)
    else
      previous_def
    end
  end
end
