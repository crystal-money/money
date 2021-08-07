require "../spec_helper"

describe Money::Allocate do
  describe "#allocate" do
    context "with all zeros" do
      it "allocates evenly" do
        Money.us_dollar(100).allocate([0, 0]).map(&.cents).should eq [50, 50]
      end
    end

    it "takes no action when one gets all" do
      Money.us_dollar(5).allocate({1.0}).map(&.cents).should eq [5]
    end

    it "keeps currencies intact" do
      Money.us_dollar(5).allocate({1}).all?(&.currency.==(:usd)).should be_true
    end

    it "does not lose pennies" do
      Money.us_dollar(5.5).allocate({0.4, 0.6}).map(&.cents).should eq [220, 330]
    end

    it "does not lose pennies" do
      moneys = Money.us_dollar(100).allocate({0.333, 0.333, 0.333})
      moneys.map(&.cents).should eq [34, 33, 33]
    end

    it "does not round rationals" do
      splits = 7.times.map { BigRational.new(950, 6650) }.to_a
      moneys = Money.us_dollar(6650).allocate(splits)
      moneys.map(&.cents).should eq [950] * 7
    end

    it "handles mixed split types" do
      splits = {BigRational.new(1, 4), 0.25, 0.25, BigDecimal.new("0.25")}
      moneys = Money.us_dollar(100).allocate(splits)
      moneys.map(&.cents).should eq [25] * 4
    end

    context "negative amount" do
      it "does not lose pennies" do
        moneys = Money.us_dollar(-100).allocate({0.333, 0.333, 0.333})
        moneys.map(&.cents).should eq [-34, -33, -33]
      end

      it "allocates the same way as positive amounts" do
        ratios = {0.6667, 0.3333}

        Money.us_dollar(10_00).allocate(ratios).map(&.cents).should eq [6_67, 3_33]
        Money.us_dollar(-10_00).allocate(ratios).map(&.cents).should eq [-6_67, -3_33]
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
      moneys = Money.us_dollar(2).split(2)
      moneys.map(&.cents).should eq [1, 1]
    end

    it "may distribute no money to some parties if there isn't enough to go around" do
      moneys = Money.us_dollar(2).split(3)
      moneys.map(&.cents).should eq [1, 1, 0]
    end

    it "does not lose pennies" do
      moneys = Money.us_dollar(5).split(2)
      moneys.map(&.cents).should eq [3, 2]
    end

    it "splits a dollar" do
      moneys = Money.us_dollar(100).split(3)
      moneys.map(&.cents).should eq [34, 33, 33]
    end
  end
end
