require "xml"
require "log"

class Money::Currency
  # Currency rate provider using data sourced from a daily feed of
  # [European Central Bank](https://www.ecb.europa.eu).
  #
  # NOTE: Supports only `EUR`-based conversions.
  class RateProvider::ECB < RateProvider
    include RateProvider::HTTP
    include RateProvider::OneToMany

    Log = ::Log.for(self)

    def base_currency_code : String
      "EUR"
    end

    getter host : URI do
      URI.parse("https://www.ecb.europa.eu")
    end

    def initialize(*, @host = nil)
    end

    # <https://www.ecb.europa.eu/stats/policy_and_exchange_rates/euro_reference_exchange_rates/html/index.en.html>
    protected def exchange_rates : Array(NativeRate)
      Log.debug { "Fetching exchange rates for #{base_currency_code}" }

      request("/stats/eurofxref/eurofxref-daily.xml") do |response|
        result = XML.parse(response.body_io)
        rates =
          result.xpath_nodes("//*[@currency and @rate]")

        rates.map do |node|
          NativeRate.new(node["currency"], node["rate"].to_big_d)
        end
      end
    end
  end
end
