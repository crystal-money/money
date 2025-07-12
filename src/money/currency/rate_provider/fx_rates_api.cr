require "log"

class Money::Currency
  # [FXRatesAPI](https://fxratesapi.com/) currency rate provider.
  class RateProvider::FXRatesAPI < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      ENV["FXRATES_API_KEY"]? ||
        raise "Missing `FXRATES_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.fxratesapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://fxratesapi.com/docs/endpoints/list-available-currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "api_key": api_key,
      }
      request("/currencies", params) do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result.keys

        currencies
      end
    end

    # <https://fxratesapi.com/docs/endpoints/latest-exchange-rates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "api_key":    api_key,
        "base":       base.code,
        "currencies": target.code,
      }
      request("/latest", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise RateProviderError.new(
            result["error"],
            result["description"]?)
        end

        if rate = result.dig?("rates", target.code)
          Rate.new(base, target, rate.to_s.to_big_d)
        end
      end
    end
  end
end
