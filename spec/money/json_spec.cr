require "../spec_helper"

describe Money do
  foo_json = %q({
    "amount": "10.00",
    "currency": "USD"
  })

  describe ".from_json" do
    context "(object)" do
      it "returns unserialized Money object" do
        foo_money = Money.from_json(foo_json)
        foo_money.fractional.should eq 10_00
        foo_money.amount.should eq 10.0
        foo_money.currency.should eq Money::Currency.find("USD")
      end
    end

    context "(string)" do
      it "returns Money object parsed from string" do
        Money.from_json(%q("$10.00")).should eq Money.new(10_00, "USD")
      end
      it "raises Parse::Error when invalid string is given" do
        expect_raises(Money::Parse::Error) { Money.from_json(%q("10 FOO")) }
      end
    end
  end

  describe "#to_json" do
    it "works as intended" do
      Money.from_json(foo_json).to_json.should eq Money.new(10_00, "USD").to_json
    end
  end
end
