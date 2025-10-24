class Money::Currency
  # Currency converter to be used with JSON and YAML serialization.
  #
  # ```
  # require "json"
  # require "yaml"
  # require "money"
  #
  # record FooWithCurrency, currency : Money::Currency do
  #   include JSON::Serializable
  #   include YAML::Serializable
  #
  #   @[JSON::Field(converter: Money::Currency::Converter)]
  #   @[YAML::Field(converter: Money::Currency::Converter)]
  #   @currency : Money::Currency
  # end
  #
  # foo = FooWithCurrency.new(Money::Currency.find("USD"))
  # foo.to_json # => "{\"currency\":\"USD\"}"
  # foo.to_yaml # => "---\ncurrency: USD\n"
  # ```
  module Converter
    extend self

    if_defined?(:JSON) do
      def from_json(pull : JSON::PullParser) : Currency
        Currency.find(pull.read_string)
      end

      def to_json(currency : Currency, json : JSON::Builder)
        json.string(currency.code)
      end
    end

    if_defined?(:YAML) do
      def from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : Currency
        unless node.is_a?(YAML::Nodes::Scalar)
          node.raise "Expected scalar, not #{node.kind}"
        end
        Currency.find(node.value)
      end

      def to_yaml(currency : Currency, yaml : YAML::Nodes::Builder)
        yaml.scalar(currency.code)
      end
    end
  end
end
