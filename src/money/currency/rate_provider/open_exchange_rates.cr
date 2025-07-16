require "log"

class Money::Currency
  # [Open Exchange Rates](https://openexchangerates.org/) currency rate provider.
  class RateProvider::OpenExchangeRates < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    property app_id : String do
      option_from_env("OPEN_EXCHANGE_RATES_APP_ID")
    end
    property host : URI do
      URI.parse("https://openexchangerates.org")
    end
    property? show_alternative = true

    def initialize(
      *,
      @app_id = nil,
      @host = nil,
      @show_alternative = true,
    )
    end

    # <https://docs.openexchangerates.org/reference/currencies-json>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = {
        "app_id":           app_id,
        "show_alternative": show_alternative?.to_s,
      }
      request("/api/currencies.json", params) do |response|
        result = JSON.parse(response.body_io).as_h
        currencies =
          result.keys

        currencies
      end
    end

    # <https://docs.openexchangerates.org/reference/latest-json>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "app_id":           app_id,
        "base":             base.code,
        "symbols":          target.code,
        "show_alternative": show_alternative?.to_s,
      }
      request("/api/latest.json", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
