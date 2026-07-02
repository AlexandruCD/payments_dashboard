# frozen_string_literal: true

# Rails only parses JSON/form bodies by default. The payments API also accepts
# XML request bodies (single root element, e.g. <transaction>...</transaction>),
# so register a parser and unwrap that root element to match the flat shape of
# a JSON body.
ActionDispatch::Request.parameter_parsers[Mime[:xml].symbol] = lambda do |raw_post|
  Hash.from_xml(raw_post).values.first || {}
end
