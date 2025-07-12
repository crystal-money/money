require "log"

class Money::Currency
  # [FreeCurrency](https://freecurrencyapi.com/) currency rate provider.
  class RateProvider::Freecurrency < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      option_from_env("FREECURRENCY_API_KEY")
    end
    property host : URI do
      URI.parse("https://api.freecurrencyapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://freecurrencyapi.com/docs/currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "apikey": api_key,
      }
      request("/v1/currencies", params) do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result["data"].as_h.keys

        currencies
      end
    end

    # <https://freecurrencyapi.com/docs/latest>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "apikey":        api_key,
        "base_currency": base.code,
        "currencies":    target.code,
      }
      request("/v1/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("data", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
