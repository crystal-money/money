struct Money
  # Base exception class.
  class Error < Exception
  end

  # Raised when trying to find an unknown currency.
  class UnknownCurrencyError < Error
  end

  # Raised when trying to find an unknown exchange rate.
  class UnknownRateError < Error
  end

  # Raised by `Bank::SingleCurrency` when trying to exchange currencies.
  class DifferentCurrencyError < Error
  end

  # Raised when smallest denomination of a currency is not defined.
  class UndefinedSmallestDenominationError < Error
    def initialize(message = "Smallest denomination of this currency is not defined")
      super(message)
    end
  end
end
