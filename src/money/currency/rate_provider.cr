require "../mixins/initialize_with"

class Money::Currency
  abstract class RateProvider
    include Mixin::InitializeWith

    # All registered rate providers.
    class_getter providers = {} of String => RateProvider.class

    macro inherited
      {% unless @type.abstract? %}
        {% name = @type.name.gsub(/^(.+)::(.+)$/, "\\2").underscore %}
        ::Money::Currency::RateProvider.providers[{{ name.stringify }}] = self
      {% end %}
    end

    # Returns the rate provider class for the given *name* if found,
    # `nil` otherwise.
    def self.find?(name : String) : RateProvider.class | Nil
      providers[name.underscore]?
    end

    # Returns the rate provider class for the given *name* if found,
    # raises `UnknownRateProviderError` otherwise.
    def self.find(name : String) : RateProvider.class
      find?(name) ||
        raise UnknownRateProviderError.new(name)
    end

    # Creates a new rate provider instance.
    def self.build(name : String, options : NamedTuple | Hash) : RateProvider
      find(name).new.tap do |provider|
        provider.initialize_with(options)
      end
    end

    # :ditto:
    def self.build(name : String, **options) : RateProvider
      build(name, options)
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

require "./rate_provider/*"
