require "log"
require "http/client"

class Money::Currency
  # [MoneyMorph](https://moneymorph.dev/) currency rate provider.
  class RateProvider::MoneyMorph < RateProvider
    Log = ::Log.for(self)

    property host : URI do
      URI.parse("https://moneymorph.dev")
    end

    def initialize(*, @host = nil)
    end

    # https://moneymorph.dev/#currencies
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/api/currencies") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        currencies =
          result.as_h.keys

        currencies
      end
    end

    # https://moneymorph.dev/#latest
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      client = HTTP::Client.new(host)
      client.get("/api/latest?base=#{base.code}&symbols=#{target.code}") do |response|
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
