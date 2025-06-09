require "xml"
require "log"
require "http/client"

class Money::Currency
  # [FloatRates](https://www.floatrates.com/) currency rate provider.
  class RateProvider::FloatRates < RateProvider
    Log = ::Log.for(self)

    property host : URI do
      URI.parse("https://www.floatrates.com")
    end

    def initialize(*, @host = nil)
    end

    # https://www.floatrates.com/json-feeds.html
    getter base_currency_codes : Array(String) do
      Log.debug { "Fetching supported currencies" }

      client = HTTP::Client.new(host)
      client.get("/json-feeds.html") do |response|
        unless response.status.ok?
          raise "Failed to fetch currencies: #{response.status}"
        end

        result = XML.parse_html(response.body_io)
        currencies =
          result.xpath_nodes("//li/a[starts-with(@href, 'https://www.floatrates.com/daily/')]")

        currencies.map do |node|
          node["href"].match!(/(\w+)\.json$/)[1].upcase
        end
      end
    end

    def exchange_rate?(base : Currency, other : Currency) : Rate?
      Log.debug { "Updating rate for #{base} -> #{other}" }

      client = HTTP::Client.new(host)
      client.get("/daily/#{base.code.downcase}.json") do |response|
        unless response.status.ok?
          raise "Failed to fetch rates: #{response.status}"
        end

        result = JSON.parse(response.body_io)
        rate =
          result.as_h.dig(other.code.downcase, "rate").to_s.to_big_d

        Rate.new(base, other, rate)
      end
    end
  end
end
