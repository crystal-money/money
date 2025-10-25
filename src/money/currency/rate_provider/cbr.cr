require "xml"
require "log"

class Money::Currency
  # Currency rate provider using data sourced from a daily feed of
  # [Bank of Russia](https://www.cbr.ru/).
  #
  # NOTE: Supports only `RUB`-targeted conversions.
  class RateProvider::CBR < RateProvider
    include RateProvider::HTTP
    include RateProvider::ManyToOne

    Log = ::Log.for(self)

    def target_currency_code : String
      "RUB"
    end

    getter host : URI do
      URI.parse("https://www.cbr.ru")
    end

    def initialize(*, @host = nil)
    end

    # <https://www.cbr.ru/development/SXML/>
    protected def exchange_rates : Array(Rate)
      Log.debug { "Fetching rates for target currency #{target_currency_code}" }

      request("/scripts/XML_daily.asp") do |response|
        result = XML.parse(response.body_io)
        rates =
          result.xpath_nodes("//Valute")

        rates.compact_map do |node|
          next unless currency_code = node.xpath_string("string(CharCode)").presence
          next unless rate = node.xpath_string("string(VunitRate)").presence

          Rate.new(currency_code, rate.sub(',', '.').to_big_d)
        end
      end
    end
  end
end
