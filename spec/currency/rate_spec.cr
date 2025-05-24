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
        "from": "USD",
        "to": "CAD",
        "value": 1.1,
        "updated_at": "2025-05-22T00:00:00Z"
      }
      JSON
  end

  it "#to_s" do
    rate.to_s.should eq "USD -> CAD: 1.1"
  end

  it "#from" do
    rate.from.should eq Money::Currency.find("USD")
  end

  it "#to" do
    rate.to.should eq Money::Currency.find("CAD")
  end

  it "#value" do
    rate.value.should be_a(BigDecimal)
    rate.value.should eq 1.1.to_big_d
  end
end
