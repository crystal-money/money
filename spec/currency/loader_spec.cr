require "../spec_helper"

describe Money::Currency::Loader do
  context ".load_defaults" do
    it "returns non-empty currency table hash" do
      Money::Currency.load_defaults.empty?.should be_false
    end

    it "returns common currencies within currency table hash" do
      currencies = Money::Currency.load_defaults.values.map(&.code)
      currencies.should contain "USD"
      currencies.should contain "EUR"
      currencies.should contain "BTC"
    end
  end
end
