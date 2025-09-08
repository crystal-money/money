class Money::Currency
  abstract class RateProvider
    extend Money::Registry

    alias Registry::NotFoundError = UnknownRateProviderError

    # Returns the value of the environment variable *key* or raises
    # `RequiredOptionError` if the variable is not set.
    protected def option_from_env(key : String) : String
      ENV[key]? ||
        raise RequiredOptionError.new \
          "Environment variable #{key.inspect} is required"
    end

    # Returns an array of supported base currency codes.
    abstract def base_currency_codes : Array(String)

    # Returns an array of supported target currency codes.
    def target_currency_codes : Array(String)
      base_currency_codes
    end

    # Returns the exchange rate between *base* and *target* currency, or `nil` if not found.
    abstract def exchange_rate?(base : Currency, target : Currency) : Rate?

    # Returns `true` if the provider supports the given currency pair.
    def supports_currency_pair?(base : Currency, target : Currency) : Bool
      base_currency_codes.includes?(base.code) &&
        target_currency_codes.includes?(target.code)
    end
  end
end

require "./rate_provider/error"
require "./rate_provider/http"
require "./rate_provider/*"
