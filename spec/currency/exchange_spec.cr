require "../spec_helper"

describe Money::Currency::Exchange do
  context "#initialize" do
    it "sets the rate store" do
      rate_store =
        Money::Currency::RateStore::Memory.new

      exchange = Money::Currency::Exchange.new(rate_store: rate_store)
      exchange.rate_store.should be rate_store
    end

    it "sets the rate provider" do
      rate_provider =
        Money::Currency::RateProvider::Null.new

      exchange = Money::Currency::Exchange.new(rate_provider: rate_provider)
      exchange.rate_provider.should be rate_provider
    end
  end

  context "#rate_store" do
    it "returns default rate store if set to `nil`" do
      exchange = Money::Currency::Exchange.new(rate_store: nil)
      exchange.rate_store.should be Money.default_rate_store
    end
  end

  context "#rate_provider" do
    it "returns default rate provider if set to `nil`" do
      exchange = Money::Currency::Exchange.new(rate_provider: nil)
      exchange.rate_provider.should be Money.default_rate_provider
    end
  end

  context "#exchange_rate" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.rate_store["USD", "EUR"] = 1.33

    it "returns the exchange rate between two currencies" do
      exchange.exchange_rate("USD", "EUR").should eq 1.33.to_big_d
    end

    it "return 1 if the currencies are the same" do
      exchange.exchange_rate("JPY", "JPY").should eq 1.to_big_d
    end

    it "raises an UnknownRateError exception when an unknown rate is requested" do
      expect_raises(Money::UnknownRateError) do
        exchange.exchange_rate("USD", "JPY")
      end
    end
  end

  context "#exchange_rate?" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.rate_store["USD", "EUR"] = 1.33

    it "returns the exchange rate between two currencies" do
      exchange.exchange_rate?("USD", "EUR").should eq 1.33.to_big_d
    end

    it "return 1 if the currencies are the same" do
      exchange.exchange_rate?("JPY", "JPY").should eq 1.to_big_d
    end

    it "returns nil when an unknown rate is requested" do
      exchange.exchange_rate?("USD", "JPY").should be_nil
    end
  end

  context "#exchange" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.rate_store["USD", "EUR"] = 1.33

    it "exchanges one currency to another" do
      exchange.exchange(Money.new(100, "USD"), "EUR")
        .should eq Money.new(133, "EUR")
    end

    it "returns the same amount when the currencies are the same" do
      exchange.exchange(Money.new(100, "JPY"), "JPY")
        .should eq Money.new(100, "JPY")
    end

    it "truncates extra digits" do
      exchange.exchange(Money.new(10, "USD"), "EUR")
        .should eq Money.new(13, "EUR")
    end

    it "raises an UnknownRateError exception when an unknown rate is requested" do
      expect_raises(Money::UnknownRateError) do
        exchange.exchange(Money.new(100, "USD"), "JPY")
      end
    end
  end

  context "cryptocurrencies" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.rate_store["BTC", "ETH"] = "40.55908909574122".to_big_d
    exchange.rate_store["ETH", "BTC"] = "0.024656261065523388".to_big_d

    it "handles cryptocurrencies" do
      exchange.exchange(Money.from_amount(1_000_000, "BTC"), "ETH")
        .should eq Money.from_amount("40559089.09574122", "ETH")

      exchange.exchange(Money.from_amount(1_000_000, "ETH"), "BTC")
        .should eq Money.from_amount("24656.26106552", "BTC")
    end
  end
end
