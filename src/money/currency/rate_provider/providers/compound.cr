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
    getter providers : Array(RateProvider)

    def initialize(@providers = [] of RateProvider)
    end

    def base_currency_codes : Array(String)
      currency_codes "Fetching base currencies failed", &.base_currency_codes
    end

    def target_currency_codes : Array(String)
      currency_codes "Fetching target currencies failed", &.target_currency_codes
    end

    private def currency_codes(failure_msg : String, &) : Array(String)
      providers
        .each_with_object([] of String) do |provider, currency_codes|
          if codes = yield provider
            currency_codes.concat(codes)
          end
        rescue ex
          Log.debug(exception: ex) do
            "#{failure_msg} (#{provider.class})"
          end
        end
        .uniq!
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      errors = [] of Exception

      providers.each do |provider|
        next unless provider.supports_currency_pair?(base, target)

        if rate = provider.exchange_rate?(base, target)
          return rate
        end
      rescue ex
        Log.debug(exception: ex) do
          "Fetching rate for #{base} -> #{target} failed (#{provider.class})"
        end
        errors << ex
      end

      if errors.present?
        raise AggregateError.new("Failed to fetch rate for #{base} -> #{target}", errors)
      end
    end
  end
end
