require "../mixins/initialize_with"

class Money::Currency
  abstract class RateProvider
    include Mixin::InitializeWith

    class_getter providers = {} of String => RateProvider.class

    macro inherited
      {% unless @type.abstract? %}
        {%
          name = @type.name.gsub(/^(.+)::(.+)$/, "\\2").underscore
        %}
        ::Money::Currency::RateProvider.providers[{{ name.stringify }}] = self
      {% end %}
    end

    def self.build(name : String, options : NamedTuple | Hash) : RateProvider
      providers[name.underscore].new.tap do |provider|
        provider.initialize_with(options)
      end
    end

    def self.build(name : String, **options) : RateProvider
      build(name, options)
    end

    # Returns an array of supported currency codes.
    abstract def currency_codes : Array(String)

    # Returns the exchange rate between `self` and *other* currency, or `nil` if not found.
    abstract def exchange_rate?(base : Currency, other : Currency) : Rate?

    # Returns `true` if the provider supports the given *base* currency.
    def supports_currency?(base : Currency) : Bool
      currency_codes.includes?(base.code)
    end

    # Returns `true` if the provider supports the given currency pair.
    def supports_currency_pair?(base : Currency, other : Currency) : Bool
      currency_codes.includes?(base.code) &&
        currency_codes.includes?(other.code)
    end
  end
end

require "./rate_provider/*"
