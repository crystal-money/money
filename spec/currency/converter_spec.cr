require "../spec_helper"

private record FooWithCurrency, currency : Money::Currency do
  include JSON::Serializable
  include YAML::Serializable

  @[JSON::Field(converter: Money::Currency::Converter)]
  @[YAML::Field(converter: Money::Currency::Converter)]
  @currency : Money::Currency
end

describe Money::Currency::Converter do
  pln = Money::Currency.find("PLN")

  describe ".from_json/yaml" do
    it "raises NotFoundError on unknown currency" do
      expect_raises(Money::Currency::NotFoundError) do
        FooWithCurrency.from_json(%({"currency": "FOO"}))
      end

      expect_raises(Money::Currency::NotFoundError) do
        FooWithCurrency.from_yaml("currency: FOO")
      end
    end

    it "deserializes" do
      FooWithCurrency.from_json(<<-JSON).currency.should eq pln
        {
          "currency": "PLN"
        }
        JSON

      FooWithCurrency.from_yaml(<<-YAML).currency.should eq pln
        ---
        currency: PLN\n
        YAML
    end

    describe "#to_json/yaml" do
      it "serializes" do
        FooWithCurrency.new(pln).to_pretty_json.should eq <<-JSON
          {
            "currency": "PLN"
          }
          JSON

        FooWithCurrency.new(pln).to_yaml.should eq <<-YAML
          ---
          currency: PLN\n
          YAML
      end
    end
  end
end
