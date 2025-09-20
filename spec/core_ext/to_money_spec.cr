require "../spec_helper"

describe String do
  describe "#to_money?" do
    it "returns a Money object" do
      "10.00 USD".to_money?.should eq Money.from_amount(10, "USD")
    end

    context "when :allow_ambiguous is true (default)" do
      it "returns a first matching currency for ambiguous values" do
        "$10.00".to_money?.should eq Money.from_amount(10, "USD")
      end
    end

    context "when :allow_ambiguous is false" do
      it "returns nil for ambiguous values" do
        "$10.00".to_money?(allow_ambiguous: false).should be_nil
      end
    end

    it "returns `nil` for invalid values" do
      "foo".to_money?.should be_nil
    end
  end

  describe "#to_money" do
    it "returns a Money object" do
      "10.00 USD".to_money.should eq Money.from_amount(10, "USD")
    end

    context "when :allow_ambiguous is true (default)" do
      it "returns a first matching currency for ambiguous values" do
        "$10.00".to_money.should eq Money.from_amount(10, "USD")
      end
    end

    context "when :allow_ambiguous is false" do
      it "raises `Parse::Error` for ambiguous values" do
        expect_raises(Money::Parse::Error, %(Cannot parse "$10.00")) do
          "$10.00".to_money(allow_ambiguous: false)
        end
      end
    end

    it "raises `Parse::Error` for invalid values" do
      expect_raises(Money::Parse::Error, %(Cannot parse "foo")) do
        "foo".to_money
      end
    end
  end
end

describe Number do
  describe "#to_money?" do
    it "returns a Money object with default currency" do
      111.to_money?.should eq Money.from_amount(111)
      111.5.to_money?.should eq Money.from_amount(111.5)
      111.25.to_big_d.to_money?.should eq Money.from_amount(111.25.to_big_d)
    end

    it "returns a Money object with given currency" do
      111.to_money?("PLN").should eq Money.from_amount(111, "PLN")
    end

    it "returns `nil` for invalid values" do
      Float64::INFINITY.to_money?.should be_nil
      Float64::NAN.to_money?.should be_nil
    end
  end

  describe "#to_money" do
    it "returns a Money object with default currency" do
      111.to_money.should eq Money.from_amount(111)
      111.5.to_money.should eq Money.from_amount(111.50)
      111.25.to_big_d.to_money.should eq Money.from_amount(111.25.to_big_d)
    end

    it "returns a Money object with given currency" do
      111.to_money("PLN").should eq Money.from_amount(111, "PLN")
    end

    it "raises ArgumentError for invalid values" do
      expect_raises(ArgumentError) { Float64::INFINITY.to_money }
      expect_raises(ArgumentError) { Float64::NAN.to_money }
    end
  end
end
