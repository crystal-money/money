require "../spec_helper"

describe Money::Bank::SingleCurrency do
  context "#exchange" do
    bank = Money::Bank::SingleCurrency.new

    it "raises when called" do
      expect_raises(Money::DifferentCurrencyError, "No exchanging of currencies allowed: $1.00 USD to EUR") do
        bank.exchange(Money.new(100, "USD"), Money::Currency.find("EUR"))
      end
    end
  end
end
