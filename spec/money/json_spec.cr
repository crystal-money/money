require "../spec_helper"

describe Money do
  money_json = <<-JSON
    {
      "amount": "10.00",
      "currency": "USD"
    }
    JSON

  describe ".from_json" do
    context "(object)" do
      it "returns unserialized Money object" do
        money = Money.from_json(money_json)
        money.fractional.should eq 10_00
        money.amount.should eq 10.0
        money.currency.should eq Money::Currency.find("USD")
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
      Money.from_json(money_json).to_json
        .should eq Money.new(10_00, "USD").to_json
    end
  end
end
