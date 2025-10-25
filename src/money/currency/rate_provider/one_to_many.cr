class Money::Currency
  module RateProvider::OneToMany
    protected record Rate,
      currency_code : String,
      value : BigDecimal

    abstract def base_currency_code : String

    getter base_currency_codes : Array(String) do
      [base_currency_code]
    end

    getter target_currency_codes : Array(String) do
      exchange_rates.map(&.currency_code)
    end

    def exchange_rate?(base : Currency, target : Currency) : Currency::Rate?
      return unless base.code == base_currency_code
      return unless rate = exchange_rate?(target: target)

      Currency::Rate.new(base, target, rate)
    end

    protected def exchange_rate?(*, target : Currency) : BigDecimal?
      exchange_rates
        .find(&.currency_code.==(target.code))
        .try(&.value)
    end

    protected abstract def exchange_rates : Array(Rate)
  end
end
