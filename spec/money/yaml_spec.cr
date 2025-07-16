require "../spec_helper"

describe Money do
  money_yaml = <<-YAML
    ---
    amount: 10.0
    currency: USD\n
    YAML

  describe ".from_yaml" do
    context "(object)" do
      it "returns unserialized Money object" do
        money = Money.from_yaml(money_yaml)
        money.fractional.should eq 10_00
        money.amount.should eq 10.0
        money.currency.should eq Money::Currency.find("USD")
        money.to_yaml.should eq money_yaml
      end
    end

    context "(string)" do
      it "returns Money object parsed from string" do
        Money.from_yaml("$10.00").should eq Money.new(10_00, "USD")
      end
      it "raises Parse::Error when invalid string is given" do
        expect_raises(Money::Parse::Error) { Money.from_yaml("10 FOO") }
      end
    end
  end

  describe "#to_yaml" do
    it "works as intended" do
      Money.from_yaml(money_yaml).to_yaml
        .should eq Money.new(10_00, "USD").to_yaml
    end
  end
end
