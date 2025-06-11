require "log"
require "http/client"

class Money::Currency
  # [Open Exchange Rates](https://openexchangerates.org/) currency rate provider.
  class RateProvider::OpenExchangeRates < RateProvider
    Log = ::Log.for(self)

    property app_id : String do
      ENV["OPEN_EXCHANGE_RATES_APP_ID"]? ||
        raise "Missing `OPEN_EXCHANGE_RATES_APP_ID` environment variable"
    end
    property host : URI do
      URI.parse("https://openexchangerates.org")
    end

    def initialize(*, @app_id = nil, @host = nil)
    end

    # https://docs.openexchangerates.org/reference/currencies-json
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/api/currencies.json?app_id=#{app_id}&show_alternative=true") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        currencies =
          result.as_h.keys

        currencies
      end
    end

    # https://docs.openexchangerates.org/reference/latest-json
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      client = HTTP::Client.new(host)
      client.get(
        "/api/latest.json?app_id=#{app_id}&base=#{base.code}&symbols=#{target.code}&show_alternative=true"
      ) do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        rate =
          result.as_h.dig("rates", target.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
