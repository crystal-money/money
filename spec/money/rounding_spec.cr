require "../spec_helper"

private NEAREST_CASH_VALUES = {
  {2350, "AED", 2350},
  {-2350, "AED", -2350},
  {2213, "AED", 2225},
  {-2213, "AED", -2225},
  {2212, "AED", 2200},
  {-2212, "AED", -2200},
  {178, "CHF", 180},
  {-178, "CHF", -180},
  {177, "CHF", 175},
  {-177, "CHF", -175},
  {175, "CHF", 175},
  {-175, "CHF", -175},
  {299, "USD", 299},
  {-299, "USD", -299},
  {300, "USD", 300},
  {-300, "USD", -300},
  {301, "USD", 301},
  {-301, "USD", -301},
}

describe Money::Rounding do
  describe "#rounded_to_nearest_cash_value?" do
    it "rounds to the nearest possible cash value" do
      NEAREST_CASH_VALUES.each do |(fractional, currency, expected)|
        Money.new(fractional, currency).rounded_to_nearest_cash_value?
          .should eq Money.new(expected, currency)
      end
    end

    it "returns `nil` if smallest denomination is not defined" do
      Money.new(100, "XAG").rounded_to_nearest_cash_value?.should be_nil
    end
  end

  describe "#rounded_to_nearest_cash_value!" do
    it "rounds to the nearest possible cash value" do
      NEAREST_CASH_VALUES.each do |(fractional, currency, expected)|
        Money.new(fractional, currency).rounded_to_nearest_cash_value!
          .should eq Money.new(expected, currency)
      end
    end

    it "raises an exception if smallest denomination is not defined" do
      expect_raises(Money::UndefinedSmallestDenominationError) do
        Money.new(100, "XAG").rounded_to_nearest_cash_value!
      end
    end
  end

  describe "#rounded_to_nearest_cash_value" do
    it "rounds to the nearest possible cash value" do
      NEAREST_CASH_VALUES.each do |(fractional, currency, expected)|
        Money.new(fractional, currency).rounded_to_nearest_cash_value
          .should eq Money.new(expected, currency)
      end
    end

    it "returns `self` if smallest denomination is not defined" do
      money = Money.new(100, "XAG")
      money.rounded_to_nearest_cash_value.should eq money
    end
  end

  describe "#round" do
    it "returns rounded value with given precision" do
      Money.new(10.12345, "USD").round.amount.should eq 10.to_big_d
      Money.new(10.12345, "USD").round(1).amount.should eq 10.1.to_big_d
      Money.new(10.12345, "USD").round(2).amount.should eq 10.12.to_big_d
      Money.new(10.12345, "USD").round(3).amount.should eq 10.12.to_big_d
      Money.new(10.12345, "USD").round(4).amount.should eq 10.12.to_big_d
    end

    context "with Money.infinite_precision = true" do
      it "returns rounded value with given precision" do
        Money.with_infinite_precision do
          Money.new(10.12345, "USD").round.amount.should eq 10.to_big_d
          Money.new(10.12345, "USD").round(1).amount.should eq 10.1.to_big_d
          Money.new(10.12345, "USD").round(2).amount.should eq 10.12.to_big_d
          Money.new(10.12345, "USD").round(3).amount.should eq 10.123.to_big_d
          Money.new(10.12345, "USD").round(4).amount.should eq 10.1234.to_big_d
        end
      end

      it "returns rounded value with given precision and rounding mode" do
        Money.with_infinite_precision do
          Money.new(10.12345, "USD").round.amount
            .should eq 10.to_big_d
          Money.new(10.12345, "USD").round(1, mode: :ties_even).amount
            .should eq 10.1.to_big_d
          Money.new(10.12345, "USD").round(2, mode: :ties_even).amount
            .should eq 10.12.to_big_d
          Money.new(10.12345, "USD").round(3, mode: :ties_even).amount
            .should eq 10.123.to_big_d
          Money.new(10.12345, "USD").round(4, mode: :ties_even).amount
            .should eq 10.1234.to_big_d
          Money.new(10.12345, "USD").round(4, mode: :ties_away).amount
            .should eq 10.1235.to_big_d
        end
      end
    end
  end
end
