require "log"

class Money::Currency
  # [Coinlayer](https://coinlayer.com/) currency rate provider.
  class RateProvider::Coinlayer < RateProvider
    include RateProvider::HTTP

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

    # <https://coinlayer.com/documentation#list>
    protected getter currency_codes : {Array(String), Array(String)} do
      Log.debug { "Fetching supported currencies" }

      params = {
        "access_key": access_key,
      }
      request("/list", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise "Rate provider error: #{result.dig("error", "type")}"
        end

        {
          result["crypto"].as_h.keys,
          result["fiat"].as_h.keys,
        }
      end
    end

    # <https://coinlayer.com/documentation#live>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      params = {
        "access_key": access_key,
        "target":     target.code,
        "symbols":    base.code,
      }
      request("/live", params) do |response|
        result = JSON.parse(response.body_io).as_h

        unless result["success"].as_bool
          raise "Rate provider error: #{result.dig("error", "type")}"
        end

        rate =
          result.dig("rates", base.code).to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
