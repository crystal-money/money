require "../spec_helper"

describe Money::Currency::Rate do
  rate = Money::Currency::Rate.new(
    Money::Currency.find("USD"),
    Money::Currency.find("CAD"),
    1.1.to_big_d,
    Time.parse_utc("2025-05-22", "%F"),
  )

  it ".from_json" do
    Money::Currency::Rate.from_json(rate.to_json).should eq rate
  end

  it "#to_json" do
    rate.to_json.should eq <<-JSON.gsub(/\s+/, "")
      {
        "base": "USD",
        "target": "CAD",
        "value": 1.1,
        "updated_at": "2025-05-22T00:00:00Z"
      }
      JSON
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
      "USD -> CAD: 1.0 (2025-05-23 00:00:00 UTC)",
      "USD -> CAD: 1.1 (2025-05-22 00:00:00 UTC)",
      "USD -> CAD: 1.0 (2025-05-22 00:00:00 UTC)",
      "CAD -> USD: 1.0 (2025-05-22 00:00:00 UTC)",
    ]
  end

  it "#to_s" do
    rate.to_s.should eq "USD -> CAD: 1.1"
    rate.to_s(include_updated_at: true).should eq "USD -> CAD: 1.1 (2025-05-22 00:00:00 UTC)"
  end

  it "#base" do
    rate.base.should eq Money::Currency.find("USD")
  end

  it "#target" do
    rate.target.should eq Money::Currency.find("CAD")
  end

  it "#value" do
    rate.value.should be_a BigDecimal
    rate.value.should eq 1.1.to_big_d
  end
end
