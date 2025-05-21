struct Money
  class Bank::VariableExchange < Bank
    def exchange(from : Money, to : Currency) : Money
      fractional = calculate_fractional(from, to)
      fractional *= exchange_rate(from.currency, to)

      Money.new(fractional: fractional, currency: to, bank: self)
    end

    private def calculate_fractional(from : Money, to : Currency) : BigDecimal
      ratio = from.currency.subunit_to_unit.to_big_d / to.subunit_to_unit

      from.fractional / ratio
    end
  end
end
