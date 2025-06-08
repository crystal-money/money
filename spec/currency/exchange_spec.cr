require "../spec_helper"

describe Money::Currency::Exchange do
  context "#exchange_rate" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.store["USD", "EUR"] = 1.33

    it "returns the exchange rate between two currencies" do
      exchange.exchange_rate(Money::Currency.find("USD"), Money::Currency.find("EUR"))
        .should eq 1.33.to_big_d
    end

    it "return 1 if the currencies are the same" do
      exchange.exchange_rate(Money::Currency.find("JPY"), Money::Currency.find("JPY"))
        .should eq 1.to_big_d
    end

    it "raises an UnknownRateError exception when an unknown rate is requested" do
      expect_raises(Money::UnknownRateError) do
        exchange.exchange_rate(Money::Currency.find("USD"), Money::Currency.find("JPY"))
      end
    end
  end

  context "#exchange_rate?" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.store["USD", "EUR"] = 1.33

    it "returns the exchange rate between two currencies" do
      exchange.exchange_rate?(Money::Currency.find("USD"), Money::Currency.find("EUR"))
        .should eq 1.33.to_big_d
    end

    it "return 1 if the currencies are the same" do
      exchange.exchange_rate?(Money::Currency.find("JPY"), Money::Currency.find("JPY"))
        .should eq 1.to_big_d
    end

    it "returns nil when an unknown rate is requested" do
      exchange.exchange_rate?(Money::Currency.find("USD"), Money::Currency.find("JPY"))
        .should be_nil
    end
  end

  context "#exchange" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.store["USD", "EUR"] = 1.33

    it "exchanges one currency to another" do
      exchange.exchange(Money.new(100, "USD"), Money::Currency.find("EUR"))
        .should eq Money.new(133, "EUR")
    end

    it "returns the same amount when the currencies are the same" do
      exchange.exchange(Money.new(100, "JPY"), Money::Currency.find("JPY"))
        .should eq Money.new(100, "JPY")
    end

    it "truncates extra digits" do
      exchange.exchange(Money.new(10, "USD"), Money::Currency.find("EUR"))
        .should eq Money.new(13, "EUR")
    end

    it "raises an UnknownRateError exception when an unknown rate is requested" do
      expect_raises(Money::UnknownRateError) do
        exchange.exchange(Money.new(100, "USD"), Money::Currency.find("JPY"))
      end
    end
  end

  context "cryptocurrencies" do
    exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
    exchange.store["BTC", "ETH"] = "40.55908909574122".to_big_d
    exchange.store["ETH", "BTC"] = "0.024656261065523388".to_big_d

    it "handles cryptocurrencies" do
      exchange.exchange(Money.from_amount(1_000_000, "BTC"), Money::Currency.find("ETH"))
        .should eq Money.from_amount("40559089.09574122", "ETH")

      exchange.exchange(Money.from_amount(1_000_000, "ETH"), Money::Currency.find("BTC"))
        .should eq Money.from_amount("24656.26106552", "BTC")
    end
  end
end
