require "log"
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

    # https://unirateapi.com/apidocs/#/Currency/get_api_currencies
    getter currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/api/currencies?api_key=#{api_key}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        currencies =
          result.as_h["currencies"].as_a.map(&.as_s)

        currencies
      end
    end

    # https://unirateapi.com/apidocs/#/Currency/get_api_rates
    def exchange_rate?(base : Currency, other : Currency) : Rate?
      Log.debug { "Updating rate for #{base} -> #{other}" }

      client = HTTP::Client.new(host)
      client.get(
        "/api/rates?api_key=#{api_key}&from=#{base.code}&to=#{other.code}"
      ) do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        rate =
          result.as_h["rate"].to_s.to_big_d

        Rate.new(base, other, rate)
      end
    end
  end
end
