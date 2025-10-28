{% skip_file unless @top_level.has_constant?(:JSON) %}

require "big/json"

struct Money
  include JSON::Serializable

  def self.new(pull : JSON::PullParser)
    if pull.kind.string?
      parse(pull.read_string)
    else
      previous_def
    end
  end

  # :nodoc:
  def self.from_json_object_key?(value : String) : Money
    parse(value)
  end

  # :nodoc:
  def to_json_object_key : String
    to_s
  end
end
