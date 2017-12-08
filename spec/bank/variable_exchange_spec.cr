require "../spec_helper"

describe Money::Bank::VariableExchange do
  bank = Money::Bank::VariableExchange.new.tap do |bank|
    store = bank.store = Money::Currency::RateStore::Memory.new
    store["USD", "EUR"] = 1.33
  end

  context "#exchange" do
    it "exchanges one currency to another" do
      bank.exchange(Money.new(100, "USD"), Money::Currency.find("EUR")).should eq Money.new(133, "EUR")
    end

    it "truncates extra digits" do
      bank.exchange(Money.new(10, "USD"), Money::Currency.find("EUR")).should eq Money.new(13, "EUR")
    end

    it "raises an UnknownRateError exception when an unknown rate is requested" do
      expect_raises(Money::UnknownRateError) do
        bank.exchange(Money.new(100, "USD"), Money::Currency.find("JPY"))
      end
    end
  end
end
