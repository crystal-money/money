class Money::Currency
  module RateProvider::ManyToOne
    protected record Rate,
      currency_code : String,
      value : BigDecimal

    abstract def target_currency_code : String

    getter target_currency_codes : Array(String) do
      [target_currency_code]
    end

    getter base_currency_codes : Array(String) do
      exchange_rates.map(&.currency_code)
    end

    def exchange_rate?(base : Currency, target : Currency) : Currency::Rate?
      return unless target.code == target_currency_code
      return unless rate = exchange_rate?(base: base)

      Currency::Rate.new(base, target, rate)
    end

    protected def exchange_rate?(*, base : Currency) : BigDecimal?
      exchange_rates
        .find(&.currency_code.==(base.code))
        .try(&.value)
    end

    protected abstract def exchange_rates : Array(Rate)
  end
end
