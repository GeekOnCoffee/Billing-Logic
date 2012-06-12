module CancellationPolicyHelpers
  def grace_period(val = nil)
    @grace_period ||= val
  end
end

module ProductPaymentHelpers
  def create_payment_for_profile_at_date(profile, amount, payment_date)
    profile.last_payment = OpenStruct.new(:amount => amount.to_i,
                                          :payment_date => payment_date,
                                          :refundable? => (Time.now - payment_date.to_time).to_i < grace_period)

    def profile.refundable_payment_amount(foo)
      last_payment.refundable? ? last_payment.amount : 0.0
    end
  end
end

module StrategyHelper
  def set_current_strategy(strategy, opts = {:command_builder => BillingLogic::CommandBuilders::WordBuilder})
    @strategy = strategy.new(:payment_command_builder_class => opts[:command_builder])
  end

  def strategy
    @strategy
  end
end

module StringParsers

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
                     :identifier => "#{$1} @ $#{$2}#{$3}", 
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

