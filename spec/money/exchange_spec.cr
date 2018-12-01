require "../spec_helper"

describe Money::Arithmetic do
  describe "#exchange_to" do
    bank = Money::Bank::VariableExchange.new.tap do |bank|
      store = bank.store = Money::Currency::RateStore::Memory.new
      store["EUR", "USD"] = 1.23
      store["USD", "EUR"] = 3.21
    end

    it "exchanges the amount properly" do
      with_default_bank(bank) do
        Money.new(100_00, "EUR").exchange_to("USD").should eq Money.new(123_00, "USD")
        Money.new(100_00, "USD").exchange_to("EUR").should eq Money.new(321_00, "EUR")
      end
    end

    it "does no exchange when the currencies are the same" do
      with_default_bank(bank) do
        money = Money.new(1, "USD")
        money.exchange_to("USD").should eq money
      end
    end
  end
end
