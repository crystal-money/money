require "../spec_helper"

describe Money::Constructors do
  describe ".zero" do
    it "creates a new Money object of 0 cents" do
      Money.zero.should eq Money.new(0)
    end

    it "uses default Currency::Exchange object" do
      Money.zero.exchange.should be Money.default_exchange
    end

    it "uses given Currency object" do
      Money::Currency.find("EUR").tap do |currency|
        Money.zero(currency: currency).currency.should be currency
      end
    end

    it "uses given Currency::Exchange object" do
      Money::Currency::Exchange::SingleCurrency.new.tap do |exchange|
        Money.zero(exchange: exchange).exchange.should be exchange
      end
    end
  end

  describe ".us_dollar" do
    it "creates a new Money object of the given value in USD" do
      Money.us_dollar(50).should eq Money.new(50, "USD")
    end
  end

  describe ".euro" do
    it "creates a new Money object of the given value in EUR" do
      Money.euro(50).should eq Money.new(50, "EUR")
    end
  end

  describe ".bitcoin" do
    it "creates a new Money object of the given value in BTC" do
      Money.bitcoin(50).should eq Money.new(50, "BTC")
    end
  end
end
