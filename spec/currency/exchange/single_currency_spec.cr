require "../../spec_helper"

describe Money::Currency::Exchange::SingleCurrency do
  context "#exchange" do
    exchange = Money::Currency::Exchange::SingleCurrency.new

    it "raises when called" do
      expect_raises(Money::DifferentCurrencyError, "No exchanging of currencies allowed for USD -> EUR") do
        exchange.exchange(Money.new(1_00, "USD"), Money::Currency.find("EUR"))
      end
    end
  end
end
