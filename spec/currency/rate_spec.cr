require "../spec_helper"

describe Money::Currency::Rate do
  rate = Money::Currency::Rate.new(
    Money::Currency.find("USD"),
    Money::Currency.find("CAD"),
    1.1.to_big_d,
    Time.parse_utc("2025-05-22", "%F"),
  )

  it "raises ArgumentError if given values are invalid" do
    expect_raises(ArgumentError, "Invalid rate: -100.0") do
      Money::Currency::Rate.new(
        Money::Currency.find("USD"),
        Money::Currency.find("EUR"),
        -100.to_big_d,
        Time.parse_utc("2025-05-22", "%F"),
      )
    end
    expect_raises(ArgumentError, "Invalid rate: 0.0") do
      Money::Currency::Rate.new(
        Money::Currency.find("USD"),
        Money::Currency.find("EUR"),
        0.to_big_d,
        Time.parse_utc("2025-05-22", "%F"),
      )
    end
  end

  context "JSON serialization" do
    it ".from_json" do
      Money::Currency::Rate.from_json(rate.to_json).should eq rate
    end

    it "#to_json" do
      rate.to_pretty_json.should eq <<-JSON
        {
          "base": "USD",
          "target": "CAD",
          "value": 1.1,
          "updated_at": "2025-05-22T00:00:00Z"
        }
        JSON
    end
  end

  context "YAML serialization" do
    it ".from_yaml" do
      Money::Currency::Rate.from_yaml(rate.to_yaml).should eq rate
    end

    it "#to_yaml" do
      rate.to_yaml.should eq <<-YAML
        ---
        base: USD
        target: CAD
        value: 1.1
        updated_at: 2025-05-22\n
        YAML
    end
  end

  it "#<=>" do
    rates = [
      Money::Currency::Rate.new(
        Money::Currency.find("USD"),
        Money::Currency.find("CAD"),
        1.to_big_d,
        Time.parse_utc("2025-05-23", "%F"),
      ),
      Money::Currency::Rate.new(
        Money::Currency.find("USD"),
        Money::Currency.find("CAD"),
        1.to_big_d,
        Time.parse_utc("2025-05-22", "%F"),
      ),
      Money::Currency::Rate.new(
        Money::Currency.find("USD"),
        Money::Currency.find("CAD"),
        1.1.to_big_d,
        Time.parse_utc("2025-05-22", "%F"),
      ),
      Money::Currency::Rate.new(
        Money::Currency.find("CAD"),
        Money::Currency.find("USD"),
        1.to_big_d,
        Time.parse_utc("2025-05-22", "%F"),
      ),
    ]
    rates.sort.map(&.to_s(include_updated_at: true)).should eq [
      "CAD -> USD: 1.0 (2025-05-22 00:00:00 UTC)",
      "USD -> CAD: 1.0 (2025-05-23 00:00:00 UTC)",
      "USD -> CAD: 1.1 (2025-05-22 00:00:00 UTC)",
      "USD -> CAD: 1.0 (2025-05-22 00:00:00 UTC)",
    ]
  end

  it "#to_s" do
    rate.to_s.should eq "USD -> CAD: 1.1"
    rate.to_s(include_updated_at: true).should eq "USD -> CAD: 1.1 (2025-05-22 00:00:00 UTC)"
  end

  it "#base" do
    rate.base.should eq "USD"
  end

  it "#target" do
    rate.target.should eq "CAD"
  end

  it "#value" do
    rate.value.should be_a BigDecimal
    rate.value.should eq 1.1.to_big_d
  end
end
