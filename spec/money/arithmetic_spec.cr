require "../spec_helper"

describe Money::Arithmetic do
  describe "-@" do
    it "changes the sign of a number" do
      (-Money.new(0)).should eq Money.new(0)
      (-Money.new(1)).should eq Money.new(-1)
      (-Money.new(-1)).should eq Money.new(1)
    end
  end

  describe "#sign" do
    it "returns the sign of the amount" do
      Money.new(-100).sign.should eq -1
      Money.new(0).sign.should eq 0
      Money.new(100).sign.should eq 1
    end
  end

  describe "#positive?" do
    it "returns true if the amount is greater than 0" do
      Money.new(1).positive?.should be_true
    end

    it "returns false if the amount is 0" do
      Money.new(0).positive?.should be_false
    end

    it "returns false if the amount is negative" do
      Money.new(-1).positive?.should be_false
    end
  end

  describe "#negative?" do
    it "returns true if the amount is less than 0" do
      Money.new(-1).negative?.should be_true
    end

    it "returns false if the amount is 0" do
      Money.new(0).negative?.should be_false
    end

    it "returns false if the amount is greater than 0" do
      Money.new(1).negative?.should be_false
    end
  end

  describe "#zero?" do
    it "returns whether the amount is 0" do
      Money.new(0, "USD").zero?.should be_true
      Money.new(0, "EUR").zero?.should be_true
      Money.new(1, "USD").zero?.should be_false
      Money.new(10, "JPY").zero?.should be_false
      Money.new(-1, "EUR").zero?.should be_false
    end
  end

  describe "#+" do
    it "adds other amount to current amount (same currency)" do
      (Money.new(10_00, "USD") + Money.new(90, "USD")).should eq Money.new(10_90, "USD")
      (Money.new(0, "USD") + Money.new(10_00, "USD")).should eq Money.new(10_00, "USD")
    end

    it "returns self if other amount is zero" do
      (Money.new(10_00, "USD") + Money.new(0, "EUR")).should eq Money.new(10_00, "USD")
    end

    it "converts other object amount to current currency and adds other amount to current amount (different currency)" do
      exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
      exchange.rate_store["EUR", "USD"] = 10

      with_default_exchange(exchange) do
        (Money.new(10_00, "USD") + Money.new(90, "EUR")).should eq Money.new(19_00, "USD")
      end
    end
  end

  describe "#-" do
    it "subtracts other amount from current amount (same currency)" do
      (Money.new(10_00, "USD") - Money.new(90, "USD")).should eq Money.new(9_10, "USD")
      (Money.new(0, "USD") - Money.new(10_00, "USD")).should eq Money.new(-10_00, "USD")
    end

    it "returns self if other amount is zero" do
      (Money.new(10_00, "USD") - Money.new(0, "EUR")).should eq Money.new(10_00, "USD")
    end

    it "converts other object amount to current currency and subtracts other amount to current amount (different currency)" do
      exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
      exchange.rate_store["EUR", "USD"] = 10

      with_default_exchange(exchange) do
        (Money.new(10_00, "USD") - Money.new(90, "EUR")).should eq Money.new(1_00, "USD")
      end
    end
  end

  describe "#*" do
    it "multiplies Money by Integer and returns Money" do
      tests = {
        {a: Money.new(10, "USD"), b: 4, c: Money.new(40, "USD")},
        {a: Money.new(10, "USD"), b: -4, c: Money.new(-40, "USD")},
        {a: Money.new(-10, "USD"), b: 4, c: Money.new(-40, "USD")},
        {a: Money.new(-10, "USD"), b: -4, c: Money.new(40, "USD")},
      }
      tests.each do |test|
        (test[:a] * test[:b]).should eq test[:c]
      end
    end
  end

  describe "#/" do
    it "divides Money by Integer and returns Money" do
      tests = {
        {a: Money.new(13, "USD"), b: 4, c: Money.new(3, "USD")},
        {a: Money.new(13, "USD"), b: -4, c: Money.new(-3, "USD")},
        {a: Money.new(-13, "USD"), b: 4, c: Money.new(-3, "USD")},
        {a: Money.new(-13, "USD"), b: -4, c: Money.new(3, "USD")},
      }
      tests.each do |test|
        (test[:a] / test[:b]).should eq test[:c]
      end
    end

    it "divides Money by Money (same currency) and returns BigDecimal" do
      tests = {
        {a: Money.new(13, "USD"), b: Money.new(4, "USD"), c: 3.25},
        {a: Money.new(13, "USD"), b: Money.new(-4, "USD"), c: -3.25},
        {a: Money.new(-13, "USD"), b: Money.new(4, "USD"), c: -3.25},
        {a: Money.new(-13, "USD"), b: Money.new(-4, "USD"), c: 3.25},
      }
      tests.each do |test|
        (test[:a] / test[:b]).should eq test[:c]
      end
    end

    it "divides Money by Money (different currency) and returns BigDecimal" do
      exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
      exchange.rate_store["EUR", "USD"] = 2

      with_default_exchange(exchange) do
        tests = {
          {a: Money.new(13, "USD"), b: Money.new(4, "EUR"), c: 1.625},
          {a: Money.new(13, "USD"), b: Money.new(-4, "EUR"), c: -1.625},
          {a: Money.new(-13, "USD"), b: Money.new(4, "EUR"), c: -1.625},
          {a: Money.new(-13, "USD"), b: Money.new(-4, "EUR"), c: 1.625},
        }
        tests.each do |test|
          (test[:a] / test[:b]).should eq test[:c]
        end
      end
    end
  end

  describe "#divmod" do
    it "calculates division and modulo with Integer" do
      tests = {
        {a: Money.new(13, "USD"), b: 4, c: {Money.new(3, "USD"), Money.new(1, "USD")}},
        {a: Money.new(13, "USD"), b: -4, c: {Money.new(-4, "USD"), Money.new(-3, "USD")}},
        {a: Money.new(-13, "USD"), b: 4, c: {Money.new(-4, "USD"), Money.new(3, "USD")}},
        {a: Money.new(-13, "USD"), b: -4, c: {Money.new(3, "USD"), Money.new(-1, "USD")}},
      }
      tests.each do |test|
        test[:a].divmod(test[:b]).should eq test[:c]
      end
    end

    it "calculates division and modulo with Money (same currency)" do
      tests = {
        {a: Money.new(13, "USD"), b: Money.new(4, "USD"), c: {3, Money.new(1, "USD")}},
        {a: Money.new(13, "USD"), b: Money.new(-4, "USD"), c: {-4, Money.new(-3, "USD")}},
        {a: Money.new(-13, "USD"), b: Money.new(4, "USD"), c: {-4, Money.new(3, "USD")}},
        {a: Money.new(-13, "USD"), b: Money.new(-4, "USD"), c: {3, Money.new(-1, "USD")}},
      }
      tests.each do |test|
        test[:a].divmod(test[:b]).should eq test[:c]
      end
    end

    it "calculates division and modulo with Money (different currency)" do
      exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
      exchange.rate_store["EUR", "USD"] = 2

      with_default_exchange(exchange) do
        tests = {
          {a: Money.new(13, "USD"), b: Money.new(4, "EUR"), c: {1, Money.new(5, "USD")}},
          {a: Money.new(13, "USD"), b: Money.new(-4, "EUR"), c: {-2, Money.new(-3, "USD")}},
          {a: Money.new(-13, "USD"), b: Money.new(4, "EUR"), c: {-2, Money.new(3, "USD")}},
          {a: Money.new(-13, "USD"), b: Money.new(-4, "EUR"), c: {1, Money.new(-5, "USD")}},
        }
        tests.each do |test|
          test[:a].divmod(test[:b]).should eq test[:c]
        end
      end
    end
  end

  describe "#modulo" do
    it "calculates modulo with Integer" do
      tests = {
        {a: Money.new(13, "USD"), b: 4, c: Money.new(1, "USD")},
        {a: Money.new(13, "USD"), b: -4, c: Money.new(-3, "USD")},
        {a: Money.new(-13, "USD"), b: 4, c: Money.new(3, "USD")},
        {a: Money.new(-13, "USD"), b: -4, c: Money.new(-1, "USD")},
      }
      tests.each do |test|
        test[:a].modulo(test[:b]).should eq test[:c]
      end
    end

    it "calculates modulo with Money (same currency)" do
      tests = {
        {a: Money.new(13, "USD"), b: Money.new(4, "USD"), c: Money.new(1, "USD")},
        {a: Money.new(13, "USD"), b: Money.new(-4, "USD"), c: Money.new(-3, "USD")},
        {a: Money.new(-13, "USD"), b: Money.new(4, "USD"), c: Money.new(3, "USD")},
        {a: Money.new(-13, "USD"), b: Money.new(-4, "USD"), c: Money.new(-1, "USD")},
      }
      tests.each do |test|
        test[:a].modulo(test[:b]).should eq test[:c]
      end
    end

    it "calculates modulo with Money (different currency)" do
      exchange = Money::Currency::Exchange.new(Money::Currency::RateStore::Memory.new)
      exchange.rate_store["EUR", "USD"] = 2

      with_default_exchange(exchange) do
        tests = {
          {a: Money.new(13, "USD"), b: Money.new(4, "EUR"), c: Money.new(5, "USD")},
          {a: Money.new(13, "USD"), b: Money.new(-4, "EUR"), c: Money.new(-3, "USD")},
          {a: Money.new(-13, "USD"), b: Money.new(4, "EUR"), c: Money.new(3, "USD")},
          {a: Money.new(-13, "USD"), b: Money.new(-4, "EUR"), c: Money.new(-5, "USD")},
        }
        tests.each do |test|
          test[:a].modulo(test[:b]).should eq test[:c]
        end
      end
    end
  end

  describe "#remainder" do
    it "calculates remainder with Integer" do
      tests = {
        {a: Money.new(13, "USD"), b: 4, c: Money.new(1, "USD")},
        {a: Money.new(13, "USD"), b: -4, c: Money.new(1, "USD")},
        {a: Money.new(-13, "USD"), b: 4, c: Money.new(-1, "USD")},
        {a: Money.new(-13, "USD"), b: -4, c: Money.new(-1, "USD")},
      }
      tests.each do |test|
        test[:a].remainder(test[:b]).should eq test[:c]
      end
    end
  end

  describe "#abs" do
    it "returns the absolute value as a new Money object" do
      Money.new(-1, "USD").abs.should eq Money.new(1, "USD")
    end
  end
end
