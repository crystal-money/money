require "../spec_helper"

describe Money::Allocate do
  describe "#allocate" do
    it "takes no action when one gets all" do
      Money.us_dollar(5).allocate({1.0}).should eq [Money.us_dollar(5)]
    end

    it "keeps currencies intact" do
      Money.us_dollar(5).allocate({1}).should eq [Money.us_dollar(5)]
    end

    pending "does not lose pennies" do
      moneys = Money.us_dollar(5).allocate({0.3, 0.7})
      moneys[0].should eq Money.us_dollar(2)
      moneys[1].should eq Money.us_dollar(3)
    end

    pending "does not lose pennies" do
      moneys = Money.us_dollar(100).allocate({0.333, 0.333, 0.333})
      moneys[0].cents.should eq 34
      moneys[1].cents.should eq 33
      moneys[2].cents.should eq 33
    end

    it "handles mixed split types" do
      splits = {BigRational.new(1, 4), 0.25, 0.25, BigDecimal.new("0.25")}
      moneys = Money.us_dollar(100).allocate(splits)
      moneys.each do |money|
        money.cents.should eq 25
      end
    end

    context "negative amount" do
      it "does not lose pennies" do
        moneys = Money.us_dollar(-100).allocate({0.333, 0.333, 0.333})

        moneys[0].cents.should eq(-34)
        moneys[1].cents.should eq(-33)
        moneys[2].cents.should eq(-33)
      end

      it "allocates the same way as positive amounts" do
        ratios = {0.6667, 0.3333}

        Money.us_dollar(10_00).allocate(ratios).map(&.fractional).should eq([6_67, 3_33])
        Money.us_dollar(-10_00).allocate(ratios).map(&.fractional).should eq([-6_67, -3_33])
      end
    end

    it "requires total to be less then 1" do
      expect_raises(ArgumentError) { Money.us_dollar(0.05).allocate({0.5, 0.6}) }
    end
  end

  describe "#split" do
    it "needs at least one party" do
      expect_raises(ArgumentError) { Money.us_dollar(1).split(0) }
      expect_raises(ArgumentError) { Money.us_dollar(1).split(-1) }
    end

    it "gives 1 cent to both people if we start with 2" do
      Money.us_dollar(2).split(2).should eq [Money.us_dollar(1), Money.us_dollar(1)]
    end

    it "may distribute no money to some parties if there isnt enough to go around" do
      Money.us_dollar(2).split(3).should eq [Money.us_dollar(1), Money.us_dollar(1), Money.us_dollar(0)]
    end

    it "does not lose pennies" do
      Money.us_dollar(5).split(2).should eq [Money.us_dollar(3), Money.us_dollar(2)]
    end

    it "splits a dollar" do
      moneys = Money.us_dollar(100).split(3)
      moneys[0].cents.should eq 34
      moneys[1].cents.should eq 33
      moneys[2].cents.should eq 33
    end
  end
end
