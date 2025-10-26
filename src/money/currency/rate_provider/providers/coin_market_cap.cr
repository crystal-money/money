require "log"

class Money::Currency
  # [CoinMarketCap](https://coinmarketcap.com/) currency rate provider.
  class RateProvider::CoinMarketCap < RateProvider
    include RateProvider::HTTP

    Log = ::Log.for(self)

    getter api_key : String do
      option_from_env("COIN_MARKET_CAP_API_KEY")
    end
    getter host : URI do
      URI.parse("https://pro-api.coinmarketcap.com")
    end

    getter? use_fiat : Bool = true
    getter? use_crypto : Bool = true

    def initialize(*, @api_key = nil, @host = nil, @use_fiat = true, @use_crypto = true)
    end

    getter base_currency_codes : Array(String) do
      %w[].tap do |codes|
        fiat_currency_map.each_key { |key| codes << key } if use_fiat?
        crypto_currency_map.each_key { |key| codes << key } if use_crypto?
      end
    end

    # <https://coinmarketcap.com/api/documentation/v1/#operation/getV1FiatMap>
    protected getter fiat_currency_map : Hash(String, Int32) do
      fetch_currency_map "fiat", &.itself
    end

    # <https://coinmarketcap.com/api/documentation/v1/#operation/getV1CryptocurrencyMap>
    protected getter crypto_currency_map : Hash(String, Int32) do
      fetch_currency_map "cryptocurrency", &.select(&.as_h["platform"].raw.nil?)
    end

    private def fetch_currency_map(type : String, &) : Hash(String, Int32)
      Log.debug { "Fetching supported currencies of type #{type.inspect}" }

      path = "/v1/%s/map" % URI.encode_path_segment(type)
      params = {
        "CMC_PRO_API_KEY": api_key,
      }
      request(path, params) do |response|
        result = JSON.parse(response.body_io).as_h

        currencies = yield result["data"].as_a
        currencies.to_h do |item|
          {item.as_h["symbol"].as_s, item.as_h["id"].as_i}
        end
      end
    end

    protected def currency_id(currency : Currency) : Int32?
      case {use_fiat?, use_crypto?}
      when {true, false} then fiat_currency_map[currency.code]?
      when {false, true} then crypto_currency_map[currency.code]?
      when {true, true}
        fiat_currency_map[currency.code]? ||
          crypto_currency_map[currency.code]?
      end
    end

    # <https://coinmarketcap.com/api/documentation/v1/#operation/getV2ToolsPriceconversion>
    def exchange_rate?(base : Currency, target : Currency) : Rate?
      return unless base_id = currency_id(base)
      return unless target_id = currency_id(target)

      Log.debug &.emit("Fetching rate for #{base} -> #{target}",
        base_id: base_id,
        target_id: target_id,
      )

      params = {
        "CMC_PRO_API_KEY": api_key,
        "amount":          "1",
        "id":              base_id.to_s,
        "convert_id":      target_id.to_s,
      }
      request("/v2/tools/price-conversion", params) do |response|
        result = JSON.parse(response.body_io).as_h
        rate =
          result.dig("data", "quote", target_id.to_s, "price").to_s.to_big_d

        Rate.new(base, target, rate)
      end
    end
  end
end
