require "xml"
require "log"

class Money::Currency
  # [FloatRates](https://www.floatrates.com/) currency rate provider.
  class RateProvider::FloatRates < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    getter host : URI do
      URI.parse("https://www.floatrates.com")
    end

    def initialize(*, @host = nil)
    end

    # <https://www.floatrates.com/json-feeds.html>
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      request("/json-feeds.html") do |response|
        result = XML.parse_html(response.body_io)
        currencies =
          result.xpath_nodes("//li/a[starts-with(@href, 'https://www.floatrates.com/daily/')]")

        currencies.map do |node|
          node["href"].match!(/(?<code>\w+)\.json$/)["code"].upcase
        end
      end
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      Log.debug { "Fetching rate for #{base} -> #{target}" }

      path =
        "/daily/%s.json" % URI.encode_path_segment(base.code.downcase)

      request(path) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig(target.code.downcase, "rate").to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
