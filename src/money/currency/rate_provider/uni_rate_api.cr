require "log"

class Money::Currency
  # [UniRateAPI](https://unirateapi.com/) currency rate provider.
  class RateProvider::UniRateAPI < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property api_key : String do
      option_from_env("UNIRATE_API_KEY")
    end
    property host : URI do
      URI.parse("https://api.unirateapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://unirateapi.com/apidocs/#/Currency/get_api_currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "api_key": api_key,
      }
      request("/api/currencies", params) do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result["currencies"].as_a.map(&.as_s)

        currencies
      end
    end

    # <https://unirateapi.com/apidocs/#/Currency/get_api_rates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "api_key": api_key,
        "from":    base.code,
        "to":      target.code,
      }
      request("/api/rates", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result["rate"].to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
