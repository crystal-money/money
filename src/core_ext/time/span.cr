module Time::Span::StringConverter
  private PATTERN = %r{
    (?:(?<sign>[+-])\s*)?
    (?:(?<weeks>\d+)(?:w|\s*weeks?),?\s*)?
    (?:(?<days>\d+)(?:d|\s*days?),?\s*)?
    (?:(?<hours>\d+)(?:h|\s*hours?),?\s*)?
    (?:(?<minutes>\d+)(?:m|\s*min(?:utes?)?),?\s*)?
    (?:(?<seconds>\d+)(?:s|\s*sec(?:onds?)?),?\s*)?
    (?:(?<nanoseconds>\d+)(?:ns|\s*nanoseconds?))?
  }ix

  enum Format
    Text
    Code
  end

  extend self

  # Parses a time span *string* into a `Time::Span`, or returns `nil` if the
  # string is invalid.
  #
  # Allowed suffixes:
  #
  # - week: `w`, `week(s)`
  # - day: `d`, `day(s)`
  # - hour: `h`, `hour(s)`
  # - minute: `m`, `min`, `minute(s)`
  # - second: `s`, `sec`, `second(s)`
  # - nanosecond: `ns`, `nanosecond(s)`
  #
  # Valid string examples:
  #
  # - `1w2d3h4m5s`
  # - `1w 2d 3h 4m 5s`
  # - `1w 2d 3h 4 min 5 sec`
  # - `1 week 2 days 3 hours 4 minutes 5 seconds`
  # - `1 week, 2 days, 3 hours, 4 minutes, 5 seconds`
  #
  # ```
  # Time::Span::StringConverter.parse?("1 day, 8 minutes")    # => 1.00:08:00
  # Time::Span::StringConverter.parse?("3 hours, 15 minutes") # => 03:15:00
  # ```
  def parse?(string : String) : Time::Span?
    return unless string = string.strip.presence
    return unless match = string.match_full(PATTERN)

    {% begin %}
      {% for part in %w[weeks days hours minutes seconds nanoseconds] %}
        {{ part.id }} = match[{{ part }}]?.try(&.to_i)
      {% end %}
      return unless weeks || days || hours || minutes || seconds || nanoseconds

      span = Time::Span.new(
        days: (weeks || 0) * 7 + (days || 0),
        hours: hours || 0,
        minutes: minutes || 0,
        seconds: seconds || 0,
        nanoseconds: nanoseconds || 0,
      )
      match["sign"]? == "-" ? -span : span
    {% end %}
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
  # Time::Span::StringConverter.dump(1.hour + 15.minutes)        # => "1 hour, 15 minutes"
  # Time::Span::StringConverter.dump(1.hour + 15.minutes, :code) # => "1.hour + 15.minutes"
  # ```
  def dump(value : Time::Span, format : Format = :text) : String
    is_negative = value.negative?
    value = value.abs

    parts = [] of {Int32, String}

    {% for part in %w[weeks days hours minutes seconds nanoseconds] %}
      %part = value.total_{{ part.id }}.to_i
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
