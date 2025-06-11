class Money::Currency
  # Class to ensure client code is operating in a single currency
  # by raising if an exchange attempts to happen.
  #
  # This is useful when an application uses multiple currencies but
  # it usually deals with only one currency at a time so any arithmetic
  # where exchanges happen are erroneous. Using this as the default exchange
  # means that that these mistakes don't silently do the wrong thing.
  class Exchange::SingleCurrency < Exchange
    # Raises a `DifferentCurrencyError` to remove possibility of accidentally
    # exchanging currencies.
    def exchange(from : Money, to : Currency) : Money
      raise DifferentCurrencyError.new(from.currency, to)
    end
  end
end
