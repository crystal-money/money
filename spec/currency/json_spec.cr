require "../spec_helper"

describe Money::Currency do
  foo_json = <<-JSON
    {
      "code": "FOO",
      "subunit_to_unit": 100
    }
    JSON

  describe ".from_json" do
    context "(object)" do
      it "returns unserialized Currency object" do
        foo_currency = Money::Currency.from_json(foo_json)
        foo_currency.code.should eq "FOO"
        foo_currency.decimal_places.should eq 2
      end
    end

    context "(string)" do
      it "returns Currency object using Currency.find when known key is given" do
        Money::Currency.from_json(%q("USD")).should eq Money::Currency.find("USD")
      end
      it "raises UnknownCurrencyError when unknown key is given" do
        expect_raises(Money::UnknownCurrencyError) { Money::Currency.from_json(%q("FOO")) }
      end
    end
  end

  describe "#to_json" do
    it "works as intended" do
      Money::Currency.from_json(foo_json).to_json.should eq foo_json.gsub(/\s+/, "")
    end
  end
end
