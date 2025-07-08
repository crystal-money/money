require "xml"
require "log"

class Money::Currency
  # Currency rate provider using data sourced from a daily feed of
  # [European Central Bank](https://www.ecb.europa.eu).
  class RateProvider::ECB < RateProvider
    include RateProvider::HTTP

    private BASE_CURRENCY_CODE = "EUR"

    Log = ::Log.for(self)

    property host : URI do
      URI.parse("https://www.ecb.europa.eu")
    end

    def initialize(*, @host = nil)
    end

    getter base_currency_codes : Array(String) do
      [BASE_CURRENCY_CODE]
    end

    getter target_currency_codes : Array(String) do
      exchange_rates.map(&.target.code)
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      exchange_rates.find { |rate| rate.base == base && rate.target == target }
    end

    protected def exchange_rates : Array(Rate)
      Log.debug { "Fetching exchange rates" }

      request("/stats/eurofxref/eurofxref-daily.xml") do |response|
        base =
          Currency.find(BASE_CURRENCY_CODE)

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
