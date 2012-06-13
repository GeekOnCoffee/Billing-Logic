DATE = Transform /^#{BillingLogic::CommandBuilders::DATE_REGEX}$/ do |date|
  str_to_date(date)
end

ANNIVERSARY = Transform /^(?:| on | starting on )(#{DATE})?$/ do |date|
  date
end

BILLING_CYCLE = Transform /^(\/mo|\/yr|every \d+ (?:day|month|year))$/ do |string|
  str_to_billing_cycle(string)
end

MONEY = Transform /^#{BillingLogic::CommandBuilders::MONEY_REGEX}$/ do |money|
  money
end


PRODUCT_FORMATTING = Transform /^((?:\w+) @ (?:#{MONEY})(?:|\/mo|\/yr)(?:(?:, | & )(?:\w+) @ (?:#{MONEY})(?:|\/mo|\/yr))*)$/ do |products|
  products.split(/, /).map do |string|
    str_to_product_formatting(string) 
  end.flatten
end

DESIRED_STATE = Transform /^((?:\w+) @ (?:#{MONEY}) (?:#{BILLING_CYCLE}))$/ do |string|
  string
end

ASSERTION = Transform /^(|don't |do not |)$/ do |assertion|
  !(assertion =~ /(don't |do not |ain't )/)
end


