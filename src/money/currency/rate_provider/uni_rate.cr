require "log"
require "uri"
require "uri/params"
require "http/client"

class Money::Currency
  # [UniRate](https://unirateapi.com/) currency rate provider.
  class RateProvider::UniRate < RateProvider
    Log = ::Log.for(self)

    property api_key : String do
      ENV["UNIRATE_API_KEY"]? ||
        raise "Missing `UNIRATE_API_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.unirateapi.com")
    end

    def initialize(*, @api_key = nil, @host = nil)
    end

    # <https://unirateapi.com/apidocs/#/Currency/get_api_currencies>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      params = URI::Params.encode({
        "api_key": api_key,
      })
      client = HTTP::Client.new(host)
      client.get("/api/currencies?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        currencies =
          result["currencies"].as_a.map(&.as_s)

        currencies
      end
    end

    # <https://unirateapi.com/apidocs/#/Currency/get_api_rates>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = URI::Params.encode({
        "api_key": api_key,
        "from":    base.code,
        "to":      target.code,
      })
      client = HTTP::Client.new(host)
      client.get("/api/rates?#{params}") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io).as_h
        rate =
          result["rate"].to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
