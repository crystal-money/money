module Time::Span::StringConverter
  private PATTERN = %r{
    (?:(?<sign>[+-])\s*)?
    (?:(?<days>\d+)(?:d|\s*days?),?\s*)?
    (?:(?<hours>\d+)(?:h|\s*hours?),?\s*)?
    (?:(?<minutes>\d+)(?:m|\s*min(?:utes?)?),?\s*)?
    (?:(?<seconds>\d+)(?:s|\s*sec(?:onds?)?))?
  }ix

  enum Format
    Text
    Code
  end

  extend self

  # Parses a time span *string* into a `Time::Span`, or returns `nil` if the
  # string is invalid.
  #
  # Valid examples:
  #
  # ```
  # "1d2h3m4s"
  # "1d 2h 3m 4s"
  # "1d 2h 3 min 4 sec"
  # "1 day 2 hours 3 minutes 4 seconds"
  # "1 day, 2 hours, 3 minutes, 4 seconds"
  # ```
  #
  # ```
  # parse?("1 day, 8 minutes")    # => 1.00:08:00
  # parse?("3 hours, 15 minutes") # => 03:15:00
  # ```
  def parse?(string : String) : Time::Span?
    return unless string = string.strip.presence
    return unless match = string.match_full(PATTERN)
    return unless match["days"]? || match["hours"]? || match["minutes"]? || match["seconds"]?

    span = Time::Span.new(
      days: match["days"]?.try(&.to_i) || 0,
      hours: match["hours"]?.try(&.to_i) || 0,
      minutes: match["minutes"]?.try(&.to_i) || 0,
      seconds: match["seconds"]?.try(&.to_i) || 0,
    )
    match["sign"]? == "-" ? -span : span
  end

  # :ditto:
  #
  # Raises an `ArgumentError` if the string is invalid.
  def parse(string : String) : Time::Span
    parse?(string) ||
      raise ArgumentError.new "Invalid time span: #{string.inspect}"
  end

  # Returns given time span *value* in the textual format.
  #
  # ```
  # dump(1.hour + 15.minutes)        # => "1 hour, 15 minutes"
  # dump(1.hour + 15.minutes, :code) # => "1.hour + 15.minutes"
  # ```
  def dump(value : Time::Span, format : Format = :text) : String
    is_negative = value.negative?
    value = value.abs

    parts = [] of {Int32, String}

    {% for part in %w[days hours minutes seconds] %}
      %part = value.total_{{ part.id }}.round(:to_zero).to_i
      if %part.positive?
        parts << { %part, {{ part }}[..(%part == 1 ? -2 : nil)] }
        value -= %part.{{ part.id }}
      end
    {% end %}

    return "" if parts.empty?

    result =
      case format
      in .text? then parts.join(", ", &.join(' '))
      in .code? then parts.join(" + ", &.join('.'))
      end

    return result unless is_negative

    case format
    in .text? then "-#{result}"
    in .code? then "-(#{result})"
    end
  end

  if_defined?(:JSON) do
    def from_json(pull : ::JSON::PullParser) : Time::Span
      parse(pull.read_string)
    end

    def to_json(value : Time::Span, json : ::JSON::Builder)
      json.string dump(value)
    end
  end

  if_defined?(:YAML) do
    def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Time::Span
      unless node.is_a?(YAML::Nodes::Scalar)
        node.raise "Expected scalar, not #{node.kind}"
      end
      parse(node.value)
    end

    def to_yaml(value : Time::Span, yaml : ::YAML::Nodes::Builder)
      yaml.scalar dump(value)
    end
  end
end
