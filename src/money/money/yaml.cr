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
end
