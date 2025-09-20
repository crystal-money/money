class String
  # Returns a `Money` instance parsed from `self` if possible, `nil` otherwise.
  #
  # See also `Money.parse?`.
  def to_money?(*, allow_ambiguous = true) : Money?
    Money.parse?(self, allow_ambiguous: allow_ambiguous)
  end

  # Returns a `Money` instance parsed from `self`.
  #
  # See also `Money.parse`.
  def to_money(*, allow_ambiguous = true) : Money
    Money.parse(self, allow_ambiguous: allow_ambiguous)
  end
end

struct Number
  # Returns a `Money` instance parsed from `self` if possible, `nil` otherwise.
  #
  # See also `Money.from_amount`.
  def to_money?(currency = Money.default_currency) : Money?
    Money.from_amount(self, currency) rescue nil
  end

  # Returns a `Money` instance parsed from `self`.
  #
  # See also `Money.from_amount`.
  def to_money(currency = Money.default_currency) : Money
    Money.from_amount(self, currency)
  end
end
