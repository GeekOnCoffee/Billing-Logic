DATE = Transform /^(\d+\/\d+\/\d+)$/ do |date|
  str_to_date(date)
end

ANNIVERSARY = Transform /^(?:| on | starting on )(#{DATE})?$/ do |date|
  date
end

BILLING_CYCLE = Transform /^(\/mo|\/yr|every \d+ (?:day|month|year))$/ do |string|
  str_to_billing_cycle(string)
end

MONEY = Transform /^\$([\d\.]+)$/ do |money|
  money
end

PRODUCT_FORMATTING = Transform /^((?:\w+) @ (?:#{MONEY})(?:|\/mo|\/yr)(?:, (?:\w+) @ (?:#{MONEY})(?:|\/mo|\/yr))*)$/ do |products|
  products.split(/, /).map do |product_string|
    product_string =~ /(\w+) @ \$([\d\.]+)(\/mo|\/yr)?/
    billing_cycle = $3 ? BillingLogic::BillingCycle.new(:frequency => 1, :period => $3.include?('mo') ? :month : :year) : nil
    OpenStruct.new(:name => $1, :price => $2, :id => "#{$1} @ #{$2}", :billing_cycle => billing_cycle)
  end
end

DESIRED_STATE = Transform /^((?:\w+) @ (?:#{MONEY}) (?:#{BILLING_CYCLE}))$/ do |string|
  string
end

ASSERTION = Transform /^(|don't |do not |)$/ do |assertion|
  !(assertion =~ /(don't |do not |ain't )/)
end


