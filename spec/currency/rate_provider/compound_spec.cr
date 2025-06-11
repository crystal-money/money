require "../../spec_helper"

class Money::Currency
  class RateProvider::CompoundDummy < RateProvider
    getter base_currency_codes : Array(String)
    getter target_currency_codes : Array(String)
    getter rates : Hash({String, String}, Rate)

    def initialize(
      @base_currency_codes = %w[],
      @target_currency_codes = %w[],
      @rates = {} of {String, String} => Rate,
      *,
      @simulate_error = false,
    )
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      raise "Simulated error" if @simulate_error
      @rates[{base.code, target.code}]?
    end
  end
end

describe Money::Currency::RateProvider::Compound do
  usd = Money::Currency.find("USD")
  cad = Money::Currency.find("CAD")
  eur = Money::Currency.find("EUR")

  rate_usd_cad = Money::Currency::Rate.new(usd, cad, 1.5.to_big_d)
  rate_eur_usd = Money::Currency::Rate.new(eur, usd, 1.1.to_big_d)

  provider1 = Money::Currency::RateProvider::CompoundDummy.new(
    base_currency_codes: %w[EUR USD],
    target_currency_codes: %w[USD CAD],
    rates: { {"USD", "CAD"} => rate_usd_cad }
  )
  provider2 = Money::Currency::RateProvider::CompoundDummy.new(
    base_currency_codes: %w[EUR],
    target_currency_codes: %w[USD],
    rates: { {"EUR", "USD"} => rate_eur_usd }
  )

  compound = Money::Currency::RateProvider::Compound.new(
    [provider1, provider2] of Money::Currency::RateProvider
  )

  describe "#base_currency_codes" do
    it "returns unique base currency codes from all providers" do
      compound.base_currency_codes.sort.should eq ["EUR", "USD"]
    end
  end

  describe "#target_currency_codes" do
    it "returns unique target currency codes from all providers" do
      compound.target_currency_codes.sort.should eq ["CAD", "USD"]
    end
  end

  describe "#exchange_rate?" do
    it "returns the rate from the first provider that supports the pair" do
      compound.exchange_rate?(usd, cad).should eq rate_usd_cad
      compound.exchange_rate?(eur, usd).should eq rate_eur_usd
    end

    it "returns nil if no provider supports the pair" do
      compound.exchange_rate?(usd, eur).should be_nil
    end

    it "skips providers that raise exceptions and continues" do
      error_provider =
        Money::Currency::RateProvider::CompoundDummy.new(simulate_error: true)

      compound_with_error = Money::Currency::RateProvider::Compound.new(
        [error_provider, provider2] of Money::Currency::RateProvider
      )
      compound_with_error.exchange_rate?(eur, usd).should eq rate_eur_usd
    end
  end
end
