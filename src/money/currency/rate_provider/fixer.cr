require "log"
require "http/client"

class Money::Currency
  # [Fixer](https://fixer.io/) currency rate provider.
  class RateProvider::Fixer < RateProvider
    Log = ::Log.for(self)

    property access_key : String do
      ENV["FIXER_ACCESS_KEY"]? ||
        raise "Missing `FIXER_ACCESS_KEY` environment variable"
    end
    property host : URI do
      URI.parse("https://data.fixer.io")
    end

    def initialize(*, @access_key = nil, @host = nil)
    end

    # https://fixer.io/documentation#supportedsymbols
    getter currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/api/symbols?access_key=#{access_key}") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        currencies =
          result.as_h["symbols"].as_h.keys

        currencies
      end
    end

    # https://fixer.io/documentation#latestrates
    def exchange_rate?(base : Currency, other : Currency) : Rate?
      Log.debug { "Updating rate for #{base} -> #{other}" }

      client = HTTP::Client.new(host)
      client.get(
        "/api/latest?access_key=#{access_key}&base=#{base.code}&symbols=#{other.code}"
      ) do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)

        unless result.as_h["success"].as_bool
          raise "Rate provider error: #{result.as_h.dig("error", "type")}"
        end

        rate =
          result.as_h.dig("rates", other.code).to_s.to_big_d

        Rate.new(base, other, rate)
      end
    end
  end
end
