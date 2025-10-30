class Money::Currency
  module RateProvider::OneToMany
    abstract def base_currency_code : String

    getter base_currency_codes : Array(String) do
      [base_currency_code]
    end

    getter target_currency_codes : Array(String) do
      target_exchange_rates.map(&.target)
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      return unless base.code == base_currency_code

      target_exchange_rates
        .find(&.target.==(target.code))
    end

    protected abstract def target_exchange_rates : Array(Rate)
  end
end
