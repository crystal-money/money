require "json"

class Money::Currency
  JSON.mapping({
    priority:              {type: Int32?, setter: false},
    iso_numeric:           {type: UInt32?, setter: false},
    code:                  {type: String, setter: false},
    name:                  {type: String?, setter: false},
    symbol:                {type: String?, setter: false},
    alternate_symbols:     {type: Array(String)?, setter: false},
    subunit:               {type: String?, setter: false},
    subunit_to_unit:       {type: UInt64, setter: false},
    symbol_first?:         {type: Bool?, setter: false},
    html_entity:           {type: String?, setter: false},
    decimal_mark:          {type: String?, setter: false},
    thousands_separator:   {type: String?, setter: false},
    smallest_denomination: {type: UInt32?, setter: false},
  })

  def self.new(pull : JSON::PullParser)
    case pull.kind
    when JSON::PullParser::Kind::String
      find(pull.read_string)
    else
      previous_def
    end
  end

  struct Rate
    JSON.mapping({
      from:  {type: Currency, setter: false},
      to:    {type: Currency, setter: false},
      value: {type: Int64, setter: false},
    })

    def to_json(json : JSON::Builder)
      json.object do
        json.field "from", @from.to_s
        json.field "to", @to.to_s
        json.field "value", @value
      end
    end
  end
end
