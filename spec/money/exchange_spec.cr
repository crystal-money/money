require "../spec_helper"

describe Money::Exchange do
  exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
  exchange.rate_store["EUR", "USD"] = 1.23
  exchange.rate_store["USD", "EUR"] = 3.21

  describe "#exchange_to" do
    it "exchanges the amount properly" do
      with_default_exchange(exchange) do
        Money.new(100_00, "EUR").exchange_to("USD").should eq Money.new(123_00, "USD")
        Money.new(100_00, "USD").exchange_to("EUR").should eq Money.new(321_00, "EUR")
      end
    end

    it "returns self when the currencies are the same" do
      with_default_exchange(exchange) do
        money = Money.new(1, "USD")
        money.exchange_to("USD").should eq money
      end
    end

    it "does not exchange when the amount is zero" do
      with_default_exchange do
        Money.disallow_currency_conversion!

        Money.zero("USD").exchange_to("EUR")
          .should eq Money.zero("EUR")
      end
    end
  end

  describe "#with_same_currency" do
    it "yields the other object exchanged to self.currency" do
      with_default_exchange(exchange) do
        Money.zero("USD").with_same_currency(Money.new(100_00, "EUR")) do |other|
          other.should eq Money.new(123_00, "USD")
        end
      end
    end
  end
end
