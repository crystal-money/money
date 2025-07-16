require "../spec_helper"

describe Money::Currency do
  currency_yaml = <<-YAML
    ---
    code: FOO
    subunit_to_unit: 100\n
    YAML

  describe ".from_yaml" do
    context "(object)" do
      it "returns unserialized Currency object" do
        currency = Money::Currency.from_yaml(currency_yaml)
        currency.code.should eq "FOO"
        currency.decimal_places.should eq 2
      end
    end

    context "(string)" do
      it "returns Currency object using Currency.find when known key is given" do
        Money::Currency.from_yaml("USD").should eq Money::Currency.find("USD")
      end
      it "raises UnknownCurrencyError when unknown key is given" do
        expect_raises(Money::UnknownCurrencyError) do
          Money::Currency.from_yaml("FOO")
        end
      end
    end
  end

  describe "#to_yaml" do
    it "works as intended" do
      Money::Currency.from_yaml(currency_yaml).to_yaml
        .should eq currency_yaml
    end
  end
end
