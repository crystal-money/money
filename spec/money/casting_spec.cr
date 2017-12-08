require "../spec_helper"

describe Money::Casting do
  describe "#to_big_d" do
    it "works as documented" do
      decimal = Money.new(10_00).to_big_d
      decimal.should be_a(BigDecimal)
      decimal.should eq 10.0
    end

    it "respects :subunit_to_unit currency property" do
      decimal = Money.new(10_00, "BHD").to_big_d
      decimal.should be_a(BigDecimal)
      decimal.should eq 1.0
    end
  end

  describe "#to_f" do
    it "works as documented" do
      Money.new(10_00).to_f.should eq 10.0
    end

    it "respects :subunit_to_unit currency property" do
      Money.new(10_00, "BHD").to_f.should eq 1.0
    end
  end
end
