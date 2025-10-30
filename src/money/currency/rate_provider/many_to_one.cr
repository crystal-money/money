class Money::Currency
  module RateProvider::ManyToOne
    abstract def target_currency_code : String

    getter target_currency_codes : Array(String) do
      [target_currency_code]
    end

    getter base_currency_codes : Array(String) do
      base_exchange_rates.map(&.base)
    end

    def exchange_rate?(base : Currency, target : Currency) : Rate?
      return unless target.code == target_currency_code

      base_exchange_rates
        .find(&.base.==(base.code))
    end

    protected abstract def base_exchange_rates : Array(Rate)
  end
end
