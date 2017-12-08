require "../spec_helper"

describe Money::Arithmetic do
  describe "-@" do
    it "changes the sign of a number" do
      (-Money.new(0)).should eq Money.new(0)
      (-Money.new(1)).should eq Money.new(-1)
      (-Money.new(-1)).should eq Money.new(1)
    end
  end

  describe "#==" do
    it "returns true if both amounts are zero, even if currency differs" do
      Money.new(0, "USD").should eq Money.new(0, "USD")
      Money.new(0, "USD").should eq Money.new(0, "EUR")
      Money.new(0, "USD").should eq Money.new(0, "AUD")
      Money.new(0, "USD").should eq Money.new(0, "JPY")
    end
  end

  describe "#<=>" do
    it "compares the two object amounts (same currency)" do
      (Money.new(1_00, "USD") <=> Money.new(1_00, "USD")).should eq 0
      (Money.new(1_00, "USD") <=> Money.new(99, "USD")).should be > 0
      (Money.new(1_00, "USD") <=> Money.new(2_00, "USD")).should be < 0
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

  describe "#+" do
    it "adds other amount to current amount (same currency)" do
      (Money.new(10_00, "USD") + Money.new(90, "USD")).should eq Money.new(10_90, "USD")
    end
  end

  describe "#-" do
    it "subtracts other amount from current amount (same currency)" do
      (Money.new(10_00, "USD") - Money.new(90, "USD")).should eq Money.new(9_10, "USD")
    end
  end

  describe "#*" do
    it "multiplies Money by Integer and returns Money" do
      ts = {
        {a: Money.new(10, :USD), b: 4, c: Money.new(40, :USD)},
        {a: Money.new(10, :USD), b: -4, c: Money.new(-40, :USD)},
        {a: Money.new(-10, :USD), b: 4, c: Money.new(-40, :USD)},
        {a: Money.new(-10, :USD), b: -4, c: Money.new(40, :USD)},
      }
      ts.each do |t|
        (t[:a] * t[:b]).should eq t[:c]
      end
    end
  end

  describe "#/" do
    it "divides Money by Integer and returns Money" do
      ts = {
        {a: Money.new(13, :USD), b: 4, c: Money.new(3, :USD)},
        {a: Money.new(13, :USD), b: -4, c: Money.new(-3, :USD)},
        {a: Money.new(-13, :USD), b: 4, c: Money.new(-3, :USD)},
        {a: Money.new(-13, :USD), b: -4, c: Money.new(3, :USD)},
      }
      ts.each do |t|
        (t[:a] / t[:b]).should eq t[:c]
      end
    end

    it "divides Money by Money (same currency) and returns Float64" do
      ts = {
        {a: Money.new(13, :USD), b: Money.new(4, :USD), c: 3.25},
        {a: Money.new(13, :USD), b: Money.new(-4, :USD), c: -3.25},
        {a: Money.new(-13, :USD), b: Money.new(4, :USD), c: -3.25},
        {a: Money.new(-13, :USD), b: Money.new(-4, :USD), c: 3.25},
      }
      ts.each do |t|
        (t[:a] / t[:b]).should eq t[:c]
      end
    end
  end

  describe "#divmod" do
    it "calculates division and modulo with Integer" do
      ts = {
        {a: Money.new(13, :USD), b: 4, c: {Money.new(3, :USD), Money.new(1, :USD)}},
        {a: Money.new(13, :USD), b: -4, c: {Money.new(-4, :USD), Money.new(-3, :USD)}},
        {a: Money.new(-13, :USD), b: 4, c: {Money.new(-4, :USD), Money.new(3, :USD)}},
        {a: Money.new(-13, :USD), b: -4, c: {Money.new(3, :USD), Money.new(-1, :USD)}},
      }
      ts.each do |t|
        t[:a].divmod(t[:b]).should eq t[:c]
      end
    end

    it "calculates division and modulo with Money (same currency)" do
      ts = {
        {a: Money.new(13, :USD), b: Money.new(4, :USD), c: {3, Money.new(1, :USD)}},
        {a: Money.new(13, :USD), b: Money.new(-4, :USD), c: {-4, Money.new(-3, :USD)}},
        {a: Money.new(-13, :USD), b: Money.new(4, :USD), c: {-4, Money.new(3, :USD)}},
        {a: Money.new(-13, :USD), b: Money.new(-4, :USD), c: {3, Money.new(-1, :USD)}},
      }
      ts.each do |t|
        t[:a].divmod(t[:b]).should eq t[:c]
      end
    end
  end

  describe "#modulo" do
    it "calculates modulo with Integer" do
      ts = {
        {a: Money.new(13, :USD), b: 4, c: Money.new(1, :USD)},
        {a: Money.new(13, :USD), b: -4, c: Money.new(-3, :USD)},
        {a: Money.new(-13, :USD), b: 4, c: Money.new(3, :USD)},
        {a: Money.new(-13, :USD), b: -4, c: Money.new(-1, :USD)},
      }
      ts.each do |t|
        t[:a].modulo(t[:b]).should eq t[:c]
      end
    end

    it "calculates modulo with Money (same currency)" do
      ts = {
        {a: Money.new(13, :USD), b: Money.new(4, :USD), c: Money.new(1, :USD)},
        {a: Money.new(13, :USD), b: Money.new(-4, :USD), c: Money.new(-3, :USD)},
        {a: Money.new(-13, :USD), b: Money.new(4, :USD), c: Money.new(3, :USD)},
        {a: Money.new(-13, :USD), b: Money.new(-4, :USD), c: Money.new(-1, :USD)},
      }
      ts.each do |t|
        t[:a].modulo(t[:b]).should eq t[:c]
      end
    end
  end

  describe "#remainder" do
    it "calculates remainder with Integer" do
      ts = {
        {a: Money.new(13, :USD), b: 4, c: Money.new(1, :USD)},
        {a: Money.new(13, :USD), b: -4, c: Money.new(1, :USD)},
        {a: Money.new(-13, :USD), b: 4, c: Money.new(-1, :USD)},
        {a: Money.new(-13, :USD), b: -4, c: Money.new(-1, :USD)},
      }
      ts.each do |t|
        t[:a].remainder(t[:b]).should eq t[:c]
      end
    end
  end

  describe "#abs" do
    it "returns the absolute value as a new Money object" do
      n = Money.new(-1, :USD)
      n.abs.should eq Money.new(1, :USD)
      n.should eq Money.new(-1, :USD)
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
end
