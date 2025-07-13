require "../spec_helper"

class Money::Currency
  class RateProvider::Dummy < RateProvider
    getter base_currency_codes : Array(String) = %w[USD CAD EUR]
    getter rates : Hash({String, String}, Rate)

    def initialize
      @rates = {
        {"USD", "CAD"} => Rate.new(Currency.find("USD"), Currency.find("CAD"), 1.25.to_big_d),
        {"EUR", "USD"} => Rate.new(Currency.find("EUR"), Currency.find("USD"), 1.1.to_big_d),
      }
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      @rates[{base.code, target.code}]?
    end
  end
end

describe Money::Currency::RateProvider do
  context ".key" do
    it "returns provider key" do
      Money::Currency::RateProvider::Dummy.key.should eq "dummy"
    end
  end

  context ".providers" do
    it "registers subclasses in providers" do
      Money::Currency::RateProvider.providers.has_key?("dummy").should be_true
      Money::Currency::RateProvider.providers["dummy"]
        .should eq Money::Currency::RateProvider::Dummy
    end
  end

  context ".find?" do
    it "returns provider by name" do
      Money::Currency::RateProvider.find?("dummy")
        .should eq Money::Currency::RateProvider::Dummy
    end

    it "returns nil for unknown provider" do
      Money::Currency::RateProvider.find?("foo").should be_nil
    end
  end

  context ".find" do
    it "returns provider by name" do
      Money::Currency::RateProvider.find("dummy")
        .should eq Money::Currency::RateProvider::Dummy
    end

    it "raises ArgumentError for unknown provider" do
      expect_raises(Money::UnknownRateProviderError, "Unknown rate provider: foo") do
        Money::Currency::RateProvider.find("foo")
      end
    end
  end

  context ".build" do
    it "raises ArgumentError for unknown provider" do
      expect_raises(Money::UnknownRateProviderError, "Unknown rate provider: foo") do
        Money::Currency::RateProvider.build("foo")
      end
    end

    it "builds a provider by name" do
      provider = Money::Currency::RateProvider.build("dummy")
      provider.should be_a Money::Currency::RateProvider::Dummy
    end

    it "builds a provider with options" do
      provider = Money::Currency::RateProvider.build "dummy",
        base_currency_codes: ["USD"]
      provider.base_currency_codes.should eq ["USD"]
    end
  end

  context "#base_currency_codes" do
    it "returns supported base currency codes" do
      provider = Money::Currency::RateProvider::Dummy.new

      provider.base_currency_codes.should contain("USD")
      provider.base_currency_codes.should contain("CAD")
      provider.base_currency_codes.should contain("EUR")
    end
  end

  context "#target_currency_codes" do
    it "returns #base_currency_codes by default" do
      provider = Money::Currency::RateProvider::Dummy.new

      provider.target_currency_codes
        .should be provider.base_currency_codes
    end
  end

  context "#exchange_rate?" do
    it "returns exchange rate if available" do
      provider = Money::Currency::RateProvider::Dummy.new
      usd = Money::Currency.find("USD")
      cad = Money::Currency.find("CAD")

      rate = provider.exchange_rate?(usd, cad).should_not be_nil
      rate.value.should eq 1.25.to_big_d
    end

    it "returns nil for missing exchange rate" do
      provider = Money::Currency::RateProvider::Dummy.new
      usd = Money::Currency.find("USD")
      eur = Money::Currency.find("EUR")

      provider.exchange_rate?(usd, eur).should be_nil
    end
  end

  context "#supports_currency_pair?" do
    it "returns `true` if both codes are present" do
      provider = Money::Currency::RateProvider::Dummy.new
      usd = Money::Currency.find("USD")
      cad = Money::Currency.find("CAD")

      provider.supports_currency_pair?(usd, cad).should be_true
    end

    it "returns `false` if base is missing" do
      provider = Money::Currency::RateProvider::Dummy.new
      usd = Money::Currency.find("USD")
      jpy = Money::Currency.find("JPY")

      provider.supports_currency_pair?(jpy, usd).should be_false
    end

    it "returns `false` if target is missing" do
      provider = Money::Currency::RateProvider::Dummy.new
      usd = Money::Currency.find("USD")
      jpy = Money::Currency.find("JPY")

      provider.supports_currency_pair?(usd, jpy).should be_false
    end
  end
end
