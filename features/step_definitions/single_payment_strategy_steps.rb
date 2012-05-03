Given /^I support a Single Payment Strategy$/ do
  set_current_strategy(BillingLogic::Strategies::SinglePaymentStrategy, :command_builder => BillingLogic::CommandBuilders::AggregateWordBuilder)
end
