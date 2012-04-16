module StrategyHelper
  class WordBuilder
    class << self
      def create_recurring_payment_commands(products, next_payment_date = Date.today)
        products.map do |product|
          "add #{product.name} @ $#{product.price} on #{next_payment_date.strftime('%m/%d/%y')} renewing every #{product.billing_cycle.frequency} #{product.billing_cycle.period}"
        end
      end

      def cancel_recurring_payment_commands(*profile_ids)
        profile_ids.map do |profile_id|
          "cancel #{profile_id} now"
        end
      end
    end
  end

  def set_current_strategy(strategy)
    @strategy = strategy.new(:payment_command_builder_class => WordBuilder)
  end

  def strategy
    @strategy
  end

  def str_to_billing_cycle(string, anniversary = Date.today)
    billing_cycle = BillingLogic::BillingCycle.new
    if (string =~ /every (\d+)\s(\w+)$/)
      billing_cycle.frequency    = $1.to_i
      billing_cycle.period = $2.to_sym
    end
    billing_cycle.anniversary = anniversary
    billing_cycle
  end
  
  def str_to_date(string)
     Date.strptime(string, '%m/%d/%y')
  end

  def str_to_product_formatting(string)
    string =~ /^(\w+) @ \$([\d\.]+)/
    OpenStruct.new(:name => $1, :price => $2)
  end

  def str_to_anniversary(string)
    string =~ ANNIVERSARY
  end

end

World(StrategyHelper)

Given /^I support Independent Payment Strategy$/ do
  set_current_strategy(BillingLogic::IndependentPaymentStrategy)
end

Given /^I don't have any subscriptions$/ do
  # pending # express the regexp above with the code you wish you had
end

Given /^Today is (\d+\/\d+\/\d+)$/ do |date|
  Timecop.travel(Date.strptime(date, '%m/%d/%y'))
end

Given /^I have the following subscriptions:$/ do |table|
  # table is a Cucumber::Ast::Table
  strategy.current_state =  table.raw.map do |row|
    next_billing_date = str_to_date(row[4])
    OpenStruct.new(
               :id => row[0],
               :products =>  [OpenStruct.new(
                                  :name => str_to_product_formatting(row[0]).name,
                                  :price => str_to_product_formatting(row[0]).price, 
                                  :billing_cycle => str_to_billing_cycle(row[1])
                                 )],
               :next_payment_date =>  next_billing_date,
               :billing_cycle => str_to_billing_cycle(row[1], next_billing_date),
               :active_or_pending? => row[2] =~ /active/
              )
  end
end


When /^I change to having: (.*)$/ do |products|
  strategy.desired_state = "#{products}".split(/, /).map do |product_map|
                             product_data = str_to_product_formatting(product_map)
                             OpenStruct.new(
                                  :name => product_data.name,
                                  :price => product_data.price, 
                                  :billing_cycle => str_to_billing_cycle(product_map)
                                 )
                           end
end


Then /^I expect the following action: (add #{PRODUCT_FORMATTING} on #{DATE}.*)$/ do |command|
  strategy.command_list.should include(command)
end


Then /^I expect the following action: (cancel #{PRODUCT_FORMATTING} now)$/ do |command|
  strategy.command_list.should include(command)
end

