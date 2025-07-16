{% skip_file unless @top_level.has_constant?(:YAML) %}

require "big/yaml"

struct Money
  def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
    if node.is_a?(YAML::Nodes::Scalar)
      parse(node.value)
    else
      previous_def
    end
  end

  def to_yaml(yaml : YAML::Nodes::Builder)
    {
      amount:   amount,
      currency: currency.to_s,
    }.to_yaml(yaml)
  end
end
