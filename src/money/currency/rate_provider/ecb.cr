require "xml"
require "log"
require "http/client"

class Money::Currency
  # Currency rate provider using data sourced from a daily feed of
  # [European Central Bank](https://www.ecb.europa.eu).
  class RateProvider::ECB < RateProvider
    Log = ::Log.for(self)

    property host : URI do
      URI.parse("https://www.ecb.europa.eu")
    end

    def initialize(*, @host = nil)
    end

    property currency_codes : Array(String) do
      exchange_rates.map(&.to.code)
    end

    def exchange_rate?(base : Currency, other : Currency) : Rate?
      exchange_rates.find { |rate| rate.from == base && rate.to == other }
    end

    protected def exchange_rates : Array(Rate)
      Log.debug { "Fetching exchange rates" }

      client = HTTP::Client.new(host)
      client.get("/stats/eurofxref/eurofxref-daily.xml") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        base =
          Currency.find("EUR")

        result = XML.parse(response.body_io)
        rates =
          result.xpath_nodes("//*[@currency and @rate]").map do |node|
            Rate.new(base, Currency.find(node["currency"]), node["rate"].to_big_d)
          end

        rates
      end
    end
  end
end
