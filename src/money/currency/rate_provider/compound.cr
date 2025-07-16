require "log"

class Money::Currency
  # Currency rate provider composed of multiple other rate providers.
  class RateProvider::Compound < RateProvider
    Log = ::Log.for(self)

    if_defined?(:JSON) do
      @[JSON::Field(converter: JSON::ArrayConverter(Money::Currency::RateProvider::Converter))]
    end
    if_defined?(:YAML) do
      @[YAML::Field(converter: YAML::ArrayConverter(Money::Currency::RateProvider::Converter))]
    end
    property providers : Array(RateProvider)

    def initialize(@providers = [] of RateProvider)
    end

    def base_currency_codes : Array(String)
      providers.flat_map(&.base_currency_codes).uniq!
    end

    def target_currency_codes : Array(String)
      providers.flat_map(&.target_currency_codes).uniq!
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      errors = [] of Exception

      rate = providers.find_value do |provider|
        if provider.supports_currency_pair?(base, target)
          provider.exchange_rate?(base, target)
        end
      rescue ex
        Log.debug(exception: ex) do
          "Fetching rate for #{base} -> #{target} failed (#{provider.class})"
        end
        errors << ex
        nil
      end
      return rate if rate

      if errors.present?
        raise AggregateError.new("Failed to fetch rate for #{base} -> #{target}", errors)
      end
    end
  end
end
