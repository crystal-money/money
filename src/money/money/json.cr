require "json"
require "big/json"

struct Money
  include JSON::Serializable

  @[JSON::Field(ignore: true)]
  @exchange : Currency::Exchange?

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when .string?
      parse(pull.read_string)
    else
      previous_def
    end
  end
end
