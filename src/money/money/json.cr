{% skip_file unless @top_level.has_constant?(:JSON) %}

require "big/json"

struct Money
  def self.new(pull : JSON::PullParser)
    case pull.kind
    when .string?
      parse(pull.read_string)
    else
      previous_def
    end
  end
end
