require "log"
require "http/client"

class Money::Currency
  # [Coinlayer](https://coinlayer.com/) currency rate provider.
  class RateProvider::Coinlayer < RateProvider
    Log = ::Log.for(self)

    property access_key : String do
      ENV["COINLAYER_ACCESS_KEY"]? ||
        raise "Missing `COINLAYER_ACCESS_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://api.coinlayer.com")
    end

    def initialize(*, @access_key = nil, @host = nil)
    end

    def base_currency_codes : Array(String)
      currency_codes[0]
    end

    def target_currency_codes : Array(String)
      currency_codes[0] + currency_codes[1]
    end

    # https://coinlayer.com/documentation#list
    protected getter currency_codes : {Array(String), Array(String)} do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/list?access_key=#{access_key}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        {
          result.as_h["crypto"].as_h.keys,
          result.as_h["fiat"].as_h.keys,
        }
      end
    end

    # https://coinlayer.com/documentation#live
    def exchange_rate?(base : Currency, other : Currency) : Rate?
      Log.debug { "Updating rate for #{base} -> #{other}" }

      client = HTTP::Client.new(host)
      client.get(
        "/live?access_key=#{access_key}&target=#{other.code}&symbols=#{base.code}"
      ) do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)

        unless result.as_h["success"].as_bool
          raise "Rate provider error: #{result.as_h.dig("error", "type")}"
        end

        rate =
          result.as_h.dig("rates", base.code).to_s.to_big_d

        Rate.new(base, other, rate)
      end
    end
  end
end
