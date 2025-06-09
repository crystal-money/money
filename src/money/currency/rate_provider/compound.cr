require "log"

class Money::Currency
  # Currency rate provider composed of multiple other rate providers.
  class RateProvider::Compound < RateProvider
    Log = ::Log.for(self)

    property providers : Array(RateProvider)

    def initialize(@providers = [] of RateProvider)
    end

    def currency_codes : Array(String)
      providers.flat_map(&.currency_codes).uniq!
    end

    def exchange_rate?(base : Currency, other : Currency) : Rate?
      providers.find_value do |provider|
        if provider.supports_currency_pair?(base, other)
          provider.exchange_rate?(base, other)
        end
      rescue ex
        Log.debug(exception: ex) do
          "Fetching rate for #{base} -> #{other} failed (#{provider.class})"
        end
        nil
      end
    end
  end
end
