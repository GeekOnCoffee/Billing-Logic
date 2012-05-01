Given /^I support a Single Payment Strategy$/ do
  set_current_strategy(BillingLogic::SinglePaymentStrategy, :command_builder => CommandBuilders::AggregateWordBuilder)
end
