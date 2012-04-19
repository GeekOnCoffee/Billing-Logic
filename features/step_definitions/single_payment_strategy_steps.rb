Given /^I support a Single Payment Strategy$/ do
  set_current_strategy(BillingLogic::SinglePaymentStrategy, :command_builder => CommandBuilders::AggregateWordBuilder)
end

Then /^(?:|I )(#{ASSERTION})expect the following action: ((?:add|cancel|disable|refund \$\d+ to) \(#{PRODUCT_FORMATTING}\) @ #{MONEY}\/\w\w (?:on #{DATE}|now).*)$/ do |assertion, commands|
  commands.split(/, /).each do |command|
    # puts "\n command #{command}"
    command_list_should_include(command, assertion)
  end
end
