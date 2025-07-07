require "../spec_helper"

describe Money::Casting do
  describe "#to_big_d" do
    it "works as documented" do
      money = Money.new(10_00).to_big_d
      money.should be_a BigDecimal
      money.should eq 10.0
    end

    it "respects :subunit_to_unit currency property" do
      money = Money.new(10_00, "BHD").to_big_d
      money.should eq 1.0
    end
  end

  describe "#to_big_f" do
    it "works as documented" do
      money = Money.new(10_00).to_big_f
      money.should be_a BigFloat
      money.should eq 10.0
    end

    it "respects :subunit_to_unit currency property" do
      money = Money.new(10_00, "BHD").to_big_f
      money.should eq 1.0
    end
  end
end
