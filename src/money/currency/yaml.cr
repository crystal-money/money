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

  module RateProvider::Converter
    private struct YAMLWrapper
      include YAML::Serializable

      getter! name : String
      getter options : Hash(String, YAML::Any::Type)?
    end

    def self.from_yaml(ctx : YAML::ParseContext, node : YAML::Nodes::Node) : RateProvider
      wrapper = YAMLWrapper.new(ctx, node)

      klass =
        RateProvider.find(wrapper.name)

      if options = wrapper.options
        klass.from_yaml(options.to_yaml)
      else
        klass.from_yaml("{}")
      end
    end

    def self.to_yaml(provider : RateProvider, yaml : YAML::Nodes::Builder)
      {
        name:    provider.class.key,
        options: provider,
      }.to_yaml(yaml)
    end
  end
end
