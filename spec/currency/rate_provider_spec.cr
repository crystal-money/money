require "../spec_helper"

class Money::Currency
  class RateProvider::DummyFX < RateProvider
    getter? foo_option : Bool

    getter base_currency_codes : Array(String) = %w[USD CAD EUR]
    getter rates = {} of String => Rate

    def initialize(*, @foo_option = false)
      @rates = {
        "USD_CAD" => Rate.new(Currency.find("USD"), Currency.find("CAD"), 1.25.to_big_d),
        "EUR_USD" => Rate.new(Currency.find("EUR"), Currency.find("USD"), 1.1.to_big_d),
      }
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      @rates["%s_%s" % {base.code, target.code}]?
    end
  end
end

private class FooWithGenericProvider
  include JSON::Serializable

  @[JSON::Field(converter: Money::Currency::RateProvider::Converter)]
  property provider : Money::Currency::RateProvider

  def initialize(@provider)
  end
end

describe Money::Currency::RateProvider::Converter do
  context "JSON serialization" do
    foo_json = <<-JSON
      {
        "provider": {
          "name": "dummy_fx",
          "options": {
            "foo_option": true,
            "base_currency_codes": [
              "USD",
              "CAD",
              "EUR"
            ],
            "rates": {}
          }
        }
      }
      JSON

    it "serializes correctly" do
      provider = Money::Currency::RateProvider::DummyFX.new(foo_option: true)
      provider.rates.clear

      FooWithGenericProvider.new(provider).to_pretty_json
        .should eq foo_json
    end

    it "deserializes correctly" do
      FooWithGenericProvider.from_json(foo_json).to_pretty_json
        .should eq foo_json
    end
  end
end

describe Money::Currency::RateProvider do
  context "JSON serialization" do
    dummy_fx_provider_json = <<-JSON
      {
        "foo_option": true,
        "base_currency_codes": [
          "FOO"
        ],
        "rates": {}
      }
      JSON

    describe ".from_json" do
      it "returns unserialized object" do
        provider =
          Money::Currency::RateProvider::DummyFX.from_json(dummy_fx_provider_json)

        provider.foo_option?.should be_true
        provider.base_currency_codes.should eq %w[FOO]
        provider.rates.should be_empty
      end
    end

    describe "#to_json" do
      it "works as intended" do
        Money::Currency::RateProvider::DummyFX
          .from_json(dummy_fx_provider_json).to_pretty_json
          .should eq dummy_fx_provider_json
      end
    end
  end

  context ".key" do
    it "returns provider key" do
      Money::Currency::RateProvider::DummyFX.key.should eq "dummy_fx"
    end
  end

  context ".providers" do
    it "registers subclasses in providers" do
      Money::Currency::RateProvider.providers.has_key?("dummy_fx").should be_true
      Money::Currency::RateProvider.providers["dummy_fx"]
        .should eq Money::Currency::RateProvider::DummyFX
    end

    context "JSON serialization" do
      it "each provider is serializable" do
        Money::Currency::RateProvider.providers.each do |key, klass|
          provider = klass.new
          provider.to_json.should match /\A\{(.*)\}\z/m
        rescue ex
          fail "Failed to serialize #{key.inspect} provider: #{ex}"
        end
      end

      it "each provider is deserializable" do
        Money::Currency::RateProvider.providers.each do |key, klass|
          provider = klass.from_json(klass.new.to_json)
          provider.class.should eq klass
        rescue ex
          fail "Failed to deserialize #{key.inspect} provider: #{ex}"
        end
      end
    end
  end

  context ".find?" do
    it "returns provider by name" do
      Money::Currency::RateProvider.find?("dummy_fx")
        .should eq Money::Currency::RateProvider::DummyFX
    end

    it "returns nil for unknown provider" do
      Money::Currency::RateProvider.find?("foo").should be_nil
    end
  end

  context ".find" do
    it "returns provider by name" do
      Money::Currency::RateProvider.find("dummy_fx")
        .should eq Money::Currency::RateProvider::DummyFX
    end

    it "raises ArgumentError for unknown provider" do
      expect_raises(Money::UnknownRateProviderError, "Unknown rate provider: foo") do
        Money::Currency::RateProvider.find("foo")
      end
    end
  end

  context "#base_currency_codes" do
    it "returns supported base currency codes" do
      provider = Money::Currency::RateProvider::DummyFX.new

      provider.base_currency_codes.should contain("USD")
      provider.base_currency_codes.should contain("CAD")
      provider.base_currency_codes.should contain("EUR")
    end
  end

  context "#target_currency_codes" do
    it "returns #base_currency_codes by default" do
      provider = Money::Currency::RateProvider::DummyFX.new

      provider.target_currency_codes
        .should be provider.base_currency_codes
    end
  end

  context "#exchange_rate?" do
    it "returns exchange rate if available" do
      provider = Money::Currency::RateProvider::DummyFX.new
      usd = Money::Currency.find("USD")
      cad = Money::Currency.find("CAD")

      rate = provider.exchange_rate?(usd, cad).should_not be_nil
      rate.value.should eq 1.25.to_big_d
    end

    it "returns nil for missing exchange rate" do
      provider = Money::Currency::RateProvider::DummyFX.new
      usd = Money::Currency.find("USD")
      eur = Money::Currency.find("EUR")

      provider.exchange_rate?(usd, eur).should be_nil
    end
  end

  context "#supports_currency_pair?" do
    it "returns `true` if both codes are present" do
      provider = Money::Currency::RateProvider::DummyFX.new
      usd = Money::Currency.find("USD")
      cad = Money::Currency.find("CAD")

      provider.supports_currency_pair?(usd, cad).should be_true
    end

    it "returns `false` if base is missing" do
      provider = Money::Currency::RateProvider::DummyFX.new
      usd = Money::Currency.find("USD")
      jpy = Money::Currency.find("JPY")

      provider.supports_currency_pair?(jpy, usd).should be_false
    end

    it "returns `false` if target is missing" do
      provider = Money::Currency::RateProvider::DummyFX.new
      usd = Money::Currency.find("USD")
      jpy = Money::Currency.find("JPY")

      provider.supports_currency_pair?(usd, jpy).should be_false
    end
  end
end
