module StrategyHelper
  def set_current_strategy(strategy, opts = {:command_builder => BillingLogic::CommandBuilders::WordBuilder})
    @strategy = strategy.new(:payment_command_builder_class => opts[:command_builder])
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

  def str_to_product_formatting(strings)
    strings.split(/ & /).map do |string|
      string =~ SINGLE_PRODUCT_REGEX
      billing_cycle = $3 ? BillingLogic::BillingCycle.new(:frequency => 1, :period => $3.include?('mo') ? :month : :year) : nil
      OpenStruct.new(:name => $1, 
                     :price => $2.to_i, 
                     :id => "#{$1} @ $#{$2}#{$3}", 
                     :billing_cycle => billing_cycle, 
                     :payments => [],
                     :initial_payment => 0)
    end
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
  set_current_strategy(BillingLogic::Strategies::IndependentPaymentStrategy)
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
    products = str_to_product_formatting(row[0])
    products.each { |product| product.billing_cycle.anniversary = next_billing_date }
    billing_cycle = str_to_billing_cycle(row[0], next_billing_date)
    ostruct = OpenStruct.new(
               :id => row[0],
               :products =>  products,
               :next_payment_date =>  next_billing_date,
               :billing_cycle => billing_cycle,
               :active_or_pending? => row[1] =~ /active/,
              )
    def ostruct.refundable_payment_amount(foo)
      @refundable_payment_amount || 0.0
    end
    ostruct
  end
  # puts "\n strategy.current_state  #{strategy.current_state.first.products }"

end

When /^I change to having: (nothing|.*)$/ do |products|
  strategy.desired_state = products == 'nothing' ? [] : products
  # puts "\n strategy.desired_state  #{strategy.desired_state}"

end

# Then /^(?:|I )(#{ASSERTION})expect the following action: ((?:add|cancel|disable|refund \$\d+ to) #{PRODUCT_FORMATTING} (?:on #{DATE}|now).*)$/ do |assertion, commands|
Then /^(?:|I )(#{ASSERTION})expect the following action: ((?:remove|add|cancel|disable|refund \$\d+ to) .*)$/ do |assertion, commands|
  commands.split(/, /).each do |command|
    command_list_should_include(command, assertion)
  end
end

