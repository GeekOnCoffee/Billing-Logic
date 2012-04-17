module StrategyHelper
  class WordBuilder
    class << self
      def create_recurring_payment_commands(products, next_payment_date = Date.today)
        products.map do |product|
          if product.billing_cycle.frequency == 1
            "add #{product.id} on #{next_payment_date.strftime('%m/%d/%y')}"
          else
            "add #{product.id} on #{next_payment_date.strftime('%m/%d/%y')} renewing every #{product.billing_cycle.frequency} #{product.billing_cycle.period}"
          end
        end
      end

      def cancel_recurring_payment_commands(*profile_ids)
        profile_ids.map do |profile_id|
          "cancel #{profile_id} now"
        end
      end

      def refund_recurring_payments_command(profile_id, amount)
        "refund $#{amount} to #{profile_id} now"
      end

      def disable_subscription(profile_id)
        "disable #{profile_id} now"
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
    case string
    when /every (\d+)\s(\w+)$/
      billing_cycle.frequency    = $1.to_i
      billing_cycle.period = $2.to_sym
    when /\/mo/
      billing_cycle.frequency    = 1
      billing_cycle.period = :month
    when /\/yr/
      billing_cycle.frequency    = 1
      billing_cycle.period = :year
    end
    billing_cycle.anniversary = anniversary
    billing_cycle
  end
  
  def str_to_date(string)
     Date.strptime(string, '%m/%d/%y')
  end

  def str_to_product_formatting(string)
    # TODO: we need to support more than just year & month
    #             period_abbrev = case product.billing_cycle.period
    #                         when :year; '/yr'
    #                         when :month;'/mo'
    #                         when :week; '/wk'
    #                         when :day;  '/day'
    #                         else
    #                           product.billing_cycle.period
    #                         end
    string =~ SINGLE_PRODUCT_REGEX
    billing_cycle = $3 ? BillingLogic::BillingCycle.new(:frequency => 1, :period => $3.include?('mo') ? :month : :year) : nil
    OpenStruct.new(:name => $1, :price => $2, :id => "#{$1} @ $#{$2}#{$3}", :billing_cycle => billing_cycle, :payments => [])
  end

  def str_to_anniversary(string)
    string =~ ANNIVERSARY
  end

  def command_list_should_include(command, bool = true)
    if bool
      strategy.command_list.should include(command)
    else
      strategy.command_list.should_not include(command)
    end
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
    next_billing_date = str_to_date(row[3])
    product = str_to_product_formatting(row[0])
    product.billing_cycle.anniversary = next_billing_date
    OpenStruct.new(
               :id => row[0],
               :products =>  [product],
               :next_payment_date =>  next_billing_date,
               :billing_cycle => product.billing_cycle, # str_to_billing_cycle(row[1], next_billing_date),
               :active_or_pending? => row[1] =~ /active/,
               :last_payment_refundable? => false
              )
  end
end

When /^I change to having: (nothing|.*)$/ do |products|
  strategy.desired_state = products == 'nothing' ? [] : products
end

Then /^(?:|I )(#{ASSERTION})expect the following action: ((?:add|cancel|disable|refund \$\d+ to) #{PRODUCT_FORMATTING} (?:on #{DATE}|now).*)$/ do |assertion, commands|
  commands.split(/, /).each do |command|
    command_list_should_include(command, assertion)
  end
end

