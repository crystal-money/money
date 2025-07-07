require "log"
require "uri"
require "http/client"

class Money::Currency
  # [CurrencyBeacon](https://currencybeacon.com/) currency rate provider.
  class RateProvider::CurrencyBeacon < RateProvider
    Log = ::Log.for(self)

    property api_key : String do
      ENV["CURRENCY_BEACON_API_KEY"]? ||
        raise "Missing `CURRENCY_BEACON_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.currencybeacon.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://currencybeacon.com/api-documentation>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/v1/currencies?api_key=#{api_key}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        currencies =
          result["response"].as_a.map(&.as_h["short_code"].as_s)

        currencies
      end
    end

    # <https://currencybeacon.com/api-documentation>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      client = HTTP::Client.new(host)
      client.get("/v1/latest?api_key=#{api_key}&base=#{base.code}&symbols=#{target.code}") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h

        if rate = result.dig?("response", "rates", target.code)
          Rate.new(base, target, rate.to_s.to_big_d)
        end
      end
    end
  end
end
