class Money
  module Exchange
    # Exchanges `self` to a new `Money` object in *other_currency*.
    def exchange_to(other_currency) : Money
      other_currency = Currency.wrap(other_currency)
      if currency == other_currency
        self
      else
        bank.exchange(self, other_currency)
      end
    end

    # Yields `other` exchanged to `self.currency`.
    def with_same_currency(other : Money)
      yield other.exchange_to(currency)
    end
  end
end
