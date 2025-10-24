require "../../spec_helper"

class Money::Currency
  class RateProvider::CompoundDummy < RateProvider
    getter base_currency_codes : Array(String)
    getter target_currency_codes : Array(String)
    getter rates = {} of String => Rate

    def initialize(
      @base_currency_codes = %w[],
      @target_currency_codes = %w[],
      @rates = {} of String => Rate,
      *,
      @simulate_fx_error = false,
      @simulate_codes_error = false,
    )
    end

    def base_currency_codes : Array(String)
      raise "Simulated error (#{object_id})" if @simulate_codes_error
      previous_def
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      raise "Simulated error (#{object_id})" if @simulate_fx_error
      @rates[Rate.key(base, target)]?
    end
  end
end

describe Money::Currency::RateProvider::Compound do
  usd = Money::Currency.find("USD")
  cad = Money::Currency.find("CAD")
  eur = Money::Currency.find("EUR")

  rate_usd_cad = Money::Currency::Rate.new(
    usd, cad, 1.5.to_big_d, Time.parse_utc("2025-05-22", "%F")
  )
  rate_eur_usd = Money::Currency::Rate.new(
    eur, usd, 1.1.to_big_d, Time.parse_utc("2025-05-22", "%F")
  )

  provider1 = Money::Currency::RateProvider::CompoundDummy.new(
    base_currency_codes: %w[EUR USD],
    target_currency_codes: %w[USD CAD],
    rates: {Money::Currency::Rate.key(usd, cad) => rate_usd_cad},
  )
  provider2 = Money::Currency::RateProvider::CompoundDummy.new(
    base_currency_codes: %w[EUR],
    target_currency_codes: %w[USD],
    rates: {Money::Currency::Rate.key(eur, usd) => rate_eur_usd},
  )

  subject = Money::Currency::RateProvider::Compound.new(
    [provider1, provider2] of Money::Currency::RateProvider
  )

  context "JSON serialization" do
    dummy_provider_json = <<-JSON
      {
        "providers": [
          {
            "name": "compound_dummy",
            "options": {
              "base_currency_codes": [
                "EUR",
                "USD"
              ],
              "target_currency_codes": [
                "USD",
                "CAD"
              ],
              "rates": {
                "USD_CAD": {
                  "base": "USD",
                  "target": "CAD",
                  "value": 1.5,
                  "updated_at": "2025-05-22T00:00:00Z"
                }
              },
              "simulate_fx_error": false,
              "simulate_codes_error": false
            }
          }
        ]
      }
      JSON

    it "serializes providers" do
      compound = Money::Currency::RateProvider::Compound.new(
        [provider1] of Money::Currency::RateProvider
      )
      compound.to_pretty_json.should eq dummy_provider_json
    end

    it "deserializes providers" do
      compound = Money::Currency::RateProvider::Compound.from_json(dummy_provider_json)
      compound.to_pretty_json.should eq dummy_provider_json
    end
  end

  describe "#base_currency_codes" do
    it "returns unique base currency codes from all providers" do
      subject.base_currency_codes.sort.should eq %w[EUR USD]
    end

    it "skips providers that raise exceptions and continues" do
      error_provider =
        Money::Currency::RateProvider::CompoundDummy.new(simulate_codes_error: true)

      compound_with_error = Money::Currency::RateProvider::Compound.new(
        [error_provider, provider2] of Money::Currency::RateProvider
      )
      compound_with_error.base_currency_codes
        .should eq %w[EUR]
    end
  end

  describe "#target_currency_codes" do
    it "returns unique target currency codes from all providers" do
      subject.target_currency_codes.sort.should eq %w[CAD USD]
    end

    it "skips providers that raise exceptions and continues" do
      error_provider =
        Money::Currency::RateProvider::CompoundDummy.new(simulate_codes_error: true)

      compound_with_error = Money::Currency::RateProvider::Compound.new(
        [error_provider, provider2] of Money::Currency::RateProvider
      )
      compound_with_error.target_currency_codes
        .should eq %w[USD]
    end
  end

  describe "#exchange_rate?" do
    it "returns the rate from the first provider that supports the pair" do
      subject.exchange_rate?(usd, cad).should eq rate_usd_cad
      subject.exchange_rate?(eur, usd).should eq rate_eur_usd
    end

    it "returns nil if no provider supports the pair" do
      subject.exchange_rate?(usd, eur).should be_nil
    end

    it "skips providers that raise exceptions and continues" do
      error_provider =
        Money::Currency::RateProvider::CompoundDummy.new(simulate_fx_error: true)

      compound_with_error = Money::Currency::RateProvider::Compound.new(
        [error_provider, provider2] of Money::Currency::RateProvider
      )
      compound_with_error.exchange_rate?(eur, usd)
        .should eq rate_eur_usd
    end

    it "raises an exception if no rate is found and any matching provider raises" do
      error_provider =
        Money::Currency::RateProvider::CompoundDummy.new(
          base_currency_codes: %w[USD],
          target_currency_codes: %w[EUR],
          simulate_fx_error: true,
        )
      compound_with_error = Money::Currency::RateProvider::Compound.new(
        [error_provider, error_provider, provider2] of Money::Currency::RateProvider
      )
      message = "Failed to fetch rate for USD -> EUR: %1$s, %1$s" % {
        "Simulated error (#{error_provider.object_id})",
      }
      expect_raises(Money::AggregateError, message) do
        compound_with_error.exchange_rate?(usd, eur)
      end
    end
  end
end
