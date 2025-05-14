struct Money
  module Exchange
    # Exchanges `self` to a new `Money` object in *other_currency*.
    def exchange_to(other_currency : String | Symbol | Currency) : Money
      other_currency = Currency.wrap(other_currency)
      case
      when other_currency == currency
        self
      when zero?
        with_currency(other_currency)
      else
        bank.exchange(self, other_currency)
      end
    end

    # Yields *other* `Money` object exchanged to `self.currency`.
    def with_same_currency(other : Money, &)
      yield other.exchange_to(currency)
    end
  end
end
