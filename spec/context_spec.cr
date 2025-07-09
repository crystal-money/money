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
    it "is set to `:ties_even` by default" do
      subject.rounding_mode.should eq Number::RoundingMode::TIES_EVEN
    end
  end

  describe "#default_currency" do
    it "is set to `USD` by default" do
      subject.default_currency.should eq Money::Currency.find("USD")
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
