struct Money
  class Bank::VariableExchange < Bank
    def exchange(from : Money, to : Currency) : Money
      amount =
        from.amount * exchange_rate(from.currency, to)

      Money.new(amount: amount, currency: to, bank: self)
    end
  end
end
