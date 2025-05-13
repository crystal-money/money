require "../spec_helper"

describe Money::Allocate do
  describe "#allocate" do
    it "needs at least one part" do
      expect_raises(ArgumentError, "Need at least one part") do
        Money.us_dollar(1).allocate([] of Int32)
      end
    end

    context "whole amounts" do
      it "keeps currencies intact" do
        Money.us_dollar(100).allocate({1, 1}).all?(&.currency.==(:usd)).should be_true
      end

      it "returns the amount when array contains only one element" do
        Money.us_dollar(100).allocate({1}).map(&.cents).should eq [100]
        Money.us_dollar(100).allocate({5}).map(&.cents).should eq [100]
        Money.us_dollar(100).allocate({1.0}).map(&.cents).should eq [100]
      end

      it "splits the amount into whole parts respecting the order" do
        Money.us_dollar(100).allocate({1, 1}).map(&.cents).should eq [50, 50]
        Money.us_dollar(100).allocate({1, 1, 2}).map(&.cents).should eq [25, 25, 50]
        Money.us_dollar(100).allocate({7, 3}).map(&.cents).should eq [70, 30]
      end

      it "accepts floats as arguments" do
        Money.us_dollar(100).allocate({1.0, 1.0}).map(&.cents).should eq [50, 50]
        Money.us_dollar(100).allocate({0.1, 0.1, 0.2}).map(&.cents).should eq [25, 25, 50]
        Money.us_dollar(100).allocate({0.07, 0.03}).map(&.cents).should eq [70, 30]
        Money.us_dollar(10).allocate({0.1, 0.2, 0.1}).map(&.cents).should eq [3, 5, 2]
      end

      it "does not lose pennies" do
        Money.us_dollar(10).allocate({1, 1, 2}).map(&.cents).should eq [3, 2, 5]
        Money.us_dollar(100).allocate({1, 1, 1}).map(&.cents).should eq [34, 33, 33]
      end

      it "handles zero arguments" do
        Money.us_dollar(100).allocate({1, 1, 0}).map(&.cents).should eq [50, 50, 0]
        Money.us_dollar(100).allocate({1, 0, 1}).map(&.cents).should eq [50, 0, 50]
        Money.us_dollar(100).allocate({0, 1, 1}).map(&.cents).should eq [0, 50, 50]
        Money.us_dollar(100).allocate({1, 0, 0}).map(&.cents).should eq [100, 0, 0]
        Money.us_dollar(100).allocate({0, 1, 0}).map(&.cents).should eq [0, 100, 0]
        Money.us_dollar(100).allocate({0, 0, 1}).map(&.cents).should eq [0, 0, 100]
      end

      it "allocates evenly with all zeros" do
        Money.us_dollar(100).allocate({0, 0}).map(&.cents).should eq [50, 50]
      end

      it "does not round rationals" do
        splits = Array.new(7) { BigRational.new(950, 6650) }
        moneys = Money.us_dollar(6650).allocate(splits)
        moneys.map(&.cents).should eq [950] * 7
      end

      it "handles mixed split types" do
        splits = {BigRational.new(1, 4), 0.25, 0.25_f32, BigDecimal.new("0.25")}
        moneys = Money.us_dollar(100).allocate(splits)
        moneys.map(&.cents).should eq [25] * 4
      end
    end

    context "fractional amounts" do
      it "returns the amount when array contains only one element" do
        Money.with_infinite_precision do
          Money.new(100).allocate({1}).map(&.cents).should eq [100]
          Money.new(100).allocate({5}).map(&.cents).should eq [100]
        end
      end

      it "splits the amount into whole parts respecting the order" do
        Money.with_infinite_precision do
          Money.new(100).allocate({1, 1}).map(&.cents).should eq [50, 50]
          Money.new(100).allocate({1, 1, 2}).map(&.cents).should eq [25, 25, 50]
          Money.new(100).allocate({7, 3}).map(&.cents).should eq [70, 30]
        end
      end

      it "splits the amount proportionally to the given parts" do
        Money.with_infinite_precision do
          Money.new(10).allocate({1, 1, 2}).map(&.cents).should eq [2.5, 2.5, 5]
          Money.new(7).allocate({1, 1}).map(&.cents).should eq [3.5, 3.5]
        end
      end

      it "handles splits into repeating decimals" do
        Money.with_infinite_precision do
          amount = 100
          parts = Money.new(amount).allocate({1, 1, 1}).map(&.cents)

          # Rounding due to inconsistent BigDecimal size. In reality the
          # first 2 elements will look like the last one with a "5" at the end,
          # compensating for a missing fraction.
          parts.map(&.round(10)).should eq [
            "33.3333333333".to_big_d,
            "33.3333333333".to_big_d,
            "33.3333333333".to_big_d,
          ]
          parts.sum.should eq amount
        end
      end
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

    context "an allocations seen in the wild" do
      it "allocates the full amount" do
        amount = 700273
        allocations = {
          1.1818583143661, 1.1818583143661, 1.1818583143661, 1.1818583143661,
          1.1818583143661, 1.1818583143661, 1.1818583143661, 1.170126087450276,
          1.0, 1.0, 1.0, 1.0,
        }
        result = Money.us_dollar(amount).allocate(allocations).map(&.cents)
        result.sum.should eq amount
        result.should eq [61566, 61565, 61565, 61565, 61565, 61565, 61565, 60953, 52091, 52091, 52091, 52091]
      end

      it "allocates the full -amount" do
        amount = -700273
        allocations = {
          1.1818583143661, 1.1818583143661, 1.1818583143661, 1.1818583143661,
          1.1818583143661, 1.1818583143661, 1.1818583143661, 1.170126087450276,
          1.0, 1.0, 1.0, 1.0,
        }
        result = Money.us_dollar(amount).allocate(allocations).map(&.cents)
        result.sum.should eq amount
        result.should eq [-61566, -61565, -61565, -61565, -61565, -61565, -61565, -60953, -52091, -52091, -52091, -52091]
      end
    end
  end

  describe "#split" do
    it "needs at least one part" do
      expect_raises(ArgumentError, "Need at least one part") do
        Money.us_dollar(1).split(0)
      end
      expect_raises(ArgumentError, "Need at least one part") do
        Money.us_dollar(1).split(-1)
      end
    end

    context "whole amounts" do
      it "returns the amount when 1 is given" do
        moneys = Money.us_dollar(100).split(1)
        moneys.map(&.cents).should eq [100]
      end

      it "splits the amount into equal parts" do
        Money.us_dollar(100).split(2).map(&.cents).should eq [50, 50]
        Money.us_dollar(100).split(4).map(&.cents).should eq [25, 25, 25, 25]
        Money.us_dollar(100).split(5).map(&.cents).should eq [20, 20, 20, 20, 20]
      end

      it "may distribute no money to some parties if there isn't enough to go around" do
        moneys = Money.us_dollar(2).split(3)
        moneys.map(&.cents).should eq [1, 1, 0]
      end

      it "does not lose pennies" do
        Money.us_dollar(5).split(2).map(&.cents).should eq [3, 2]
        Money.us_dollar(2).split(3).map(&.cents).should eq [1, 1, 0]
        Money.us_dollar(100).split(3).map(&.cents).should eq [34, 33, 33]
        Money.us_dollar(100).split(6).map(&.cents).should eq [17, 17, 17, 17, 16, 16]
      end
    end

    context "fractional amounts" do
      it "returns the amount when 1 is given" do
        Money.with_infinite_precision do
          Money.new(100).split(1).map(&.cents).should eq [100]
        end
      end

      it "splits the amount into equal parts" do
        Money.with_infinite_precision do
          Money.new(100).split(2).map(&.cents).should eq [50, 50]
          Money.new(100).split(4).map(&.cents).should eq [25, 25, 25, 25]
          Money.new(100).split(5).map(&.cents).should eq [20, 20, 20, 20, 20]
        end
      end

      it "splits the amount into equal fractions" do
        Money.with_infinite_precision do
          Money.new(5).split(2).map(&.cents).should eq [2.5, 2.5]
          Money.new(5).split(4).map(&.cents).should eq [1.25, 1.25, 1.25, 1.25]
        end
      end

      it "handles splits into repeating decimals" do
        Money.with_infinite_precision do
          amount = 100
          parts = Money.new(amount).split(3).map(&.cents)

          # Rounding due to inconsistent BigDecimal size. In reality the
          # first 2 elements will look like the last one with a '5' at the end,
          # compensating for a missing fraction.
          parts.map(&.round(10)).should eq [
            "33.3333333333".to_big_d,
            "33.3333333333".to_big_d,
            "33.3333333333".to_big_d,
          ]
          parts.sum.should eq amount
        end
      end
    end
  end
end
