class Money
  class Error < Exception
  end

  class UnknownCurrencyError < Error
  end

  class UnknownRateError < Error
  end

  # Raised when trying to exchange currencies.
  class DifferentCurrencyError < Error
  end

  # Raised when smallest denomination of a currency is not defined.
  class UndefinedSmallestDenominationError < Error
  end
end
