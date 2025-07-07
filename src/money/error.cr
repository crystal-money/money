struct Money
  # Base exception class.
  class Error < Exception
  end

  # Raised when trying to find an unknown currency.
  class UnknownCurrencyError < Error
    def initialize(key)
      super("Unknown currency: #{key}")
    end
  end

  # Raised when trying to find an unknown rate provider.
  class UnknownRateProviderError < Error
    def initialize(key)
      super("Unknown rate provider: #{key}")
    end
  end

  # Raised when trying to find an unknown exchange rate.
  class UnknownRateError < Error
    def initialize(base, target)
      super("No conversion rate known for #{base} -> #{target}")
    end
  end

  # Raised by `Currency::Exchange::SingleCurrency` when trying to exchange currencies.
  class DifferentCurrencyError < Error
    def initialize(base : Currency, target : Currency)
      super("No exchanging of currencies allowed for #{base} -> #{target}")
    end
  end

  # Raised when smallest denomination of a currency is not defined.
  class UndefinedSmallestDenominationError < Error
    def initialize(currency : Currency)
      super("Smallest denomination of #{currency} currency is not defined")
    end
  end
end
