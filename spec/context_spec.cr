require "./spec_helper"

describe Money do
  it "extends `Context::Delegators`" do
    Money.should be_a Money::Context::Delegators
  end

  describe ".context" do
    it "returns a `Context` object" do
      Money.context.should be_a Money::Context
    end

    it "is an alias of `Fiber.current.money_context`" do
      Money.context.should be Fiber.current.money_context
    end
  end

  describe ".context=" do
    it "allows setting the context" do
      context = Money::Context.new

      Money.context = context
      Money.context.should be context
    end
  end
end

describe Money::Context do
  subject = Money::Context.new

  describe "#infinite_precision?" do
    it "is set to `false` by default" do
      subject.infinite_precision?.should be_false
    end
  end

  describe "#rounding_mode" do
    it "is set to `:ties_away` by default" do
      subject.rounding_mode.should eq Number::RoundingMode::TIES_AWAY
    end
  end

  describe "#default_currency" do
    it "raises UndefinedCurrencyError by default" do
      expect_raises(Money::UndefinedCurrencyError) { subject.default_currency }
    end

    context "allows setting the default currency" do
      context = Money::Context.new

      it "by Currency" do
        context.default_currency = Money::Currency.find("PLN")
        context.default_currency.should be_a Money::Currency
        context.default_currency.should eq Money::Currency.find("PLN")
      end

      it "by String" do
        context.default_currency = "EUR"
        context.default_currency.should be_a Money::Currency
        context.default_currency.should eq Money::Currency.find("EUR")
      end

      it "by Symbol" do
        context.default_currency = :xag
        context.default_currency.should be_a Money::Currency
        context.default_currency.should eq Money::Currency.find("XAG")
      end

      it "by Nil" do
        context.default_currency = nil
        expect_raises(Money::UndefinedCurrencyError, "No default currency set") do
          context.default_currency
        end
      end
    end
  end

  describe "#default_exchange" do
    it "is set to `Currency::Exchange` by default" do
      subject.default_exchange.should be_a Money::Currency::Exchange
    end
  end

  describe "#default_rate_store" do
    it "is set to `Currency::RateStore::Memory` by default" do
      subject.default_rate_store.should be_a Money::Currency::RateStore::Memory
    end
  end

  describe "#default_rate_provider" do
    it "is set to `Currency::RateProvider::Null` by default" do
      subject.default_rate_provider.should be_a Money::Currency::RateProvider::Null
    end
  end
end
