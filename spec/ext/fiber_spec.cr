require "../spec_helper"

describe Fiber do
  describe "#money_context" do
    it "returns a `Money::Context` object" do
      Fiber.current.money_context.should be_a Money::Context
    end
  end
end
