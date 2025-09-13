{% skip_file unless @top_level.has_constant?(:YAML) %}

require "big/yaml"
require "uri/yaml"

class Money::Currency
  include YAML::Serializable

  def self.new(ctx : YAML::ParseContext, node : YAML::Nodes::Node)
    if node.is_a?(YAML::Nodes::Scalar)
      find(node.value)
    else
      previous_def
    end
  end

  struct Rate
    include YAML::Serializable

    def to_yaml(yaml : YAML::Nodes::Builder)
      {
        base:       base.to_s,
        target:     target.to_s,
        value:      value,
        updated_at: updated_at,
      }.to_yaml(yaml)
    end
  end

  class Exchange
    include YAML::Serializable
  end
end
