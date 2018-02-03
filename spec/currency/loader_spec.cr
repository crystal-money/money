require "../spec_helper"

private class CurrencyLoader
  include Money::Currency::Loader
end

describe Money::Currency::Loader do
  loader = CurrencyLoader.new

  context ".load_currencies" do
    it "returns a currency table hash" do
      loader.load_currencies.should be_a Hash(String, Money::Currency)
    end

    it "returns non-empty currency table hash" do
      loader.load_currencies.empty?.should be_false
    end

    it "returns common currencies within currency table hash" do
      currencies = loader.load_currencies.values
      currencies.should contain "USD"
      currencies.should contain "EUR"
      currencies.should contain "BTC"
    end
  end
end
