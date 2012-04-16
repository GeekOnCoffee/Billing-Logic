DATE = Transform /^(\d+\/\d+\/\d+)$/ do |date|
  str_to_date(date)
end

ANNIVERSARY = Transform /^(?:| on | starting on )(#{DATE})?$/ do |date|
  date
end

BILLING_CYCLE = Transform /^(every \d+ (?:day|month|year))$/ do |string|
  str_to_billing_cycle(string)
end

MONEY = Transform /^\$([\d\.]+)$/ do |money|
  money
end

PRODUCT_FORMATTING = Transform /^(\w+) @ (#{MONEY})$/ do |product_name, price|
  OpenStruct.new(:name => product_name, :price => price, :id => "#{product_name} @ #{price}")
end

DESIRED_STATE = Transform /^((?:\w+) @ (?:#{MONEY}) (?:#{BILLING_CYCLE}))$/ do |string|
  string
end

ASSERTION = Transform /^(|don't |do not |)$/ do |assertion|
  !(assertion =~ /(don't |do not |ain't )/)
end


