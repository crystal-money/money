{% skip_file unless @top_level.has_constant?(:JSON) %}

require "big/json"

struct Money
  def self.new(pull : JSON::PullParser)
    if pull.kind.string?
      parse(pull.read_string)
    else
      previous_def
    end
  end

  def to_json(json : JSON::Builder)
    {
      amount:   amount,
      currency: currency.to_s,
    }.to_json(json)
  end
end
