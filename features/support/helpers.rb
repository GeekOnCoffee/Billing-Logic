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

  def str_to_product_formatting(str)
    str.split(/ & /).map do |string|
      BillingLogic::CommandBuilders::ProductStub.parse(string)
    end
  end

  def str_to_anniversary(string)
    string =~ ANNIVERSARY
  end

  def command_list_should_include(command, bool = true)
    command_list = strategy.command_list.map { |obj| obj.to_s }
    if bool
      command_list.should include(BillingLogic::CommandBuilders::ActionObject.from_string(command).to_s)
    else
      command_list.should_not include(BillingLogic::CommandBuilders::ActionObject.from_string(command).to_s)
    end
  end

end

