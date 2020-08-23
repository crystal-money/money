require "json"
require "big/json"
require "../../ext/big_decimal"

struct Money
  include JSON::Serializable

  @[JSON::Field(ignore: true)]
  @bank : Bank?

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when .string?
      parse(pull.read_string)
    else
      previous_def
    end
  end
end
