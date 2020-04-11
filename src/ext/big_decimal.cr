# https://github.com/crystal-lang/crystal/issues/7856
struct BigDecimal
  def to_json(json : JSON::Builder)
    json.string(self)
  end

  def to_json_object_key
    to_s
  end
end
