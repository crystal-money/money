require "log"

class Money::Currency
  # [Currency API](https://currencyapi.com/) currency rate provider.
  class RateProvider::CurrencyAPI < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      ENV["CURRENCY_API_KEY"]? ||
        raise RateProviderAPIKeyMissingError.new \
          "Missing `CURRENCY_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.currencyapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://currencyapi.com/docs/currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "apikey": api_key,
      }
      request("/v3/currencies", params) do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result["data"].as_h.keys

        currencies
      end
    end

    # <https://currencyapi.com/docs/latest>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "apikey":        api_key,
        "base_currency": base.code,
        "currencies":    target.code,
      }
      request("/v3/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("data", target.code, "value").to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
