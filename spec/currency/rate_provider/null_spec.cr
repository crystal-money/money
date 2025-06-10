require "../../spec_helper"

describe Money::Currency::RateProvider::Null do
  provider = Money::Currency::RateProvider::Null.new

  describe "#base_currency_codes" do
    it "returns an empty array" do
      provider.base_currency_codes.should be_empty
    end
  end

  describe "#target_currency_codes" do
    it "returns an empty array" do
      provider.target_currency_codes.should be_empty
    end
  end

  describe "#exchange_rate?" do
    it "returns `nil`" do
      provider
        .exchange_rate?(Money::Currency.find("USD"), Money::Currency.find("EUR"))
        .should be_nil
    end
  end
end
