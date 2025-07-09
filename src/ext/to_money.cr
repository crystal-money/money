class String
  # Returns a `Money` instance parsed from `self` if possible, `nil` otherwise.
  #
  # See also `Money.parse?`.
  def to_money?(exchange = nil, *, allow_ambiguous = true) : Money?
    money = Money.parse?(self, allow_ambiguous: allow_ambiguous)
    money.exchange = exchange if exchange && money
    money
  end

  # Returns a `Money` instance parsed from `self`.
  #
  # See also `Money.parse`.
  def to_money(exchange = nil, *, allow_ambiguous = true) : Money
    money = Money.parse(self, allow_ambiguous: allow_ambiguous)
    money.exchange = exchange if exchange
    money
  end
end

struct Number
  # Returns a `Money` instance parsed from `self` if possible, `nil` otherwise.
  #
  # See also `Money.from_amount`.
  def to_money?(currency = Money.default_currency, exchange = nil) : Money?
    Money.from_amount(self, currency, exchange) rescue nil
  end

  # Returns a `Money` instance parsed from `self`.
  #
  # See also `Money.from_amount`.
  def to_money(currency = Money.default_currency, exchange = nil) : Money
    Money.from_amount(self, currency, exchange)
  end
end
