require "../../spec_helper"

private record FooWithTimeSpan, span : Time::Span? do
  include JSON::Serializable
  include YAML::Serializable

  @[JSON::Field(converter: Time::Span::StringConverter)]
  @[YAML::Field(converter: Time::Span::StringConverter)]
  @span : Time::Span?
end

describe Time::Span::StringConverter do
  time_span = 4.days + 3.hours + 2.minutes + 1.second
  time_span_string = "4 days, 3 hours, 2 minutes, 1 second"

  describe "JSON" do
    it "converts string to Time::Span" do
      FooWithTimeSpan.from_json(%({"span": "#{time_span_string}"})).span
        .should eq time_span
    end

    it "converts Time::Span to string" do
      FooWithTimeSpan.new(time_span).to_pretty_json
        .should eq <<-JSON
          {
            "span": "#{time_span_string}"
          }
          JSON
    end
  end

  describe "YAML" do
    it "converts string to Time::Span" do
      FooWithTimeSpan.from_yaml("span: #{time_span_string}").span
        .should eq time_span
    end

    it "converts Time::Span to string" do
      FooWithTimeSpan.new(time_span).to_yaml
        .should eq <<-YAML
          ---
          span: #{time_span_string}\n
          YAML
    end
  end

  describe ".parse" do
    it "deserializes string value into a Time::Span" do
      assert_parses = ->(str : String) do
        Time::Span::StringConverter.parse?(str).should eq time_span
        Time::Span::StringConverter.parse(str).should eq time_span
      end
      assert_parses.call time_span_string
      assert_parses.call "4d3h2m1s"
      assert_parses.call "4d 3h 2m 1s"
      assert_parses.call "4d, 3h 2 min 1 sec"
      assert_parses.call "4 day 3 hours 2 minutes 1 second"
      assert_parses.call "4 days 3 hour 2 minute 1second"
      assert_parses.call "4 day, 3 hours, 2 minutes, 1 second"
      assert_parses.call "+4 days, 3 hours, 2 minutes, 1 second"
      assert_parses.call "+ 4 days, 3 hours, 2 minutes, 1 second"

      Time::Span::StringConverter.parse?("- 1 day, 2 hours")
        .should eq -(1.day + 2.hours)

      Time::Span::StringConverter.parse?("-1 day, 2 hours")
        .should eq -(1.day + 2.hours)

      Time::Span::StringConverter.parse?("0 seconds")
        .should eq Time::Span.zero
    end

    it "returns nil / raises ArgumentError for invalid inputs" do
      refute_parses = ->(str : String) do
        Time::Span::StringConverter.parse?(str).should be_nil

        expect_raises(ArgumentError, "Invalid time span: #{str.inspect}") do
          Time::Span::StringConverter.parse(str)
        end
      end
      refute_parses.call ""
      refute_parses.call "+"
      refute_parses.call "-"
      refute_parses.call "123"
      refute_parses.call "foo"
      refute_parses.call "1d-2h-3m"
      refute_parses.call "1 day,,,"
      refute_parses.call "1 min 2 day"
      refute_parses.call "1s 2 min"
      refute_parses.call "1m 2d"
    end
  end

  describe ".dump" do
    context "(format: :text)" do
      it "serializes Time::Span value into a string" do
        Time::Span::StringConverter.dump(1.day + 2.hours + 3.minutes + 4.seconds)
          .should eq "1 day, 2 hours, 3 minutes, 4 seconds"

        Time::Span::StringConverter.dump(11.days)
          .should eq "1 week, 4 days"

        Time::Span::StringConverter.dump(1.hour + 15.minutes)
          .should eq "1 hour, 15 minutes"

        Time::Span::StringConverter.dump(1.hour + 15.nanoseconds)
          .should eq "1 hour, 15 nanoseconds"
      end

      it "serializes Time::Span with zero value into a string" do
        Time::Span::StringConverter.dump(Time::Span.zero)
          .should eq "0 seconds"
      end

      it "serializes negative Time::Span value into a string" do
        Time::Span::StringConverter.dump(-(2.hours + 5.minutes))
          .should eq "-2 hours, 5 minutes"

        Time::Span::StringConverter.dump(-5.minutes)
          .should eq "-5 minutes"
      end
    end

    context "(format: :code)" do
      it "serializes Time::Span value into a string" do
        Time::Span::StringConverter.dump(1.day + 2.hours + 3.minutes + 4.seconds, :code)
          .should eq "1.day + 2.hours + 3.minutes + 4.seconds"

        Time::Span::StringConverter.dump(11.days, :code)
          .should eq "1.week + 4.days"

        Time::Span::StringConverter.dump(1.hour + 15.minutes, :code)
          .should eq "1.hour + 15.minutes"

        Time::Span::StringConverter.dump(1.hour + 15.nanoseconds, :code)
          .should eq "1.hour + 15.nanoseconds"
      end

      it "serializes Time::Span with zero value into a string" do
        Time::Span::StringConverter.dump(Time::Span.zero, :code)
          .should eq "0.seconds"
      end

      it "serializes negative Time::Span value into a string" do
        Time::Span::StringConverter.dump(-(2.hours + 5.minutes), :code)
          .should eq "-(2.hours + 5.minutes)"

        Time::Span::StringConverter.dump(-5.minutes, :code)
          .should eq "-5.minutes"
      end
    end
  end
end
