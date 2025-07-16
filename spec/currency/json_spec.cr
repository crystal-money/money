require "../spec_helper"

describe Money::Currency do
  currency_json = <<-JSON
    {
      "code": "FOO",
      "subunit_to_unit": 100
    }
    JSON

  describe ".from_json" do
    context "(object)" do
      it "returns unserialized Currency object" do
        currency = Money::Currency.from_json(currency_json)
        currency.code.should eq "FOO"
        currency.decimal_places.should eq 2
      end
    end

    context "(string)" do
      it "returns Currency object using Currency.find when known key is given" do
        Money::Currency.from_json(%q("USD")).should eq Money::Currency.find("USD")
      end
      it "raises UnknownCurrencyError when unknown key is given" do
        expect_raises(Money::UnknownCurrencyError) do
          Money::Currency.from_json(%q("FOO"))
        end
      end
    end
  end

  describe ".from_json_object_key?" do
    it "works as intended" do
      hash = Hash(Money::Currency, String).from_json(%({"USD": "foo"}))
      hash.should eq({Money::Currency.find("USD") => "foo"})
    end
  end

  describe "#to_json" do
    it "works as intended" do
      Money::Currency.from_json(currency_json).to_pretty_json
        .should eq currency_json
    end
  end

  describe "#to_json_object_key" do
    it "works as intended" do
      hash = {Money::Currency.find("USD") => "foo"}
      hash.to_json.should eq %({"USD":"foo"})
    end
  end
end
