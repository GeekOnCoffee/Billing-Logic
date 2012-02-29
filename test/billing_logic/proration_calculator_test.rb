require File.expand_path(File.dirname(__FILE__) + '/../helper')
require 'bigdecimal'

class ProrationCalculatorTest < Test::Unit::TestCase
  include BillingLogic
  context "calculating monthly prorations" do
    setup do
      @anniversary_date = Date.parse('1/2/2012')
      @cycle = BillingCycle.new(period: :month, 
                                frequency: 1, 
                                anniversary: @anniversary_date)
      @price = 29.0 
      @calculator = ProrationCalculator.new(billing_cycle: @cycle, 
                                            price: @price)
    end

    should "recall price & cycles" do
      assert_equal @price, @calculator.price
      assert_equal @cycle, @calculator.billing_cycle
    end

    context "from a date prior to the anniversary date" do
      should "be able to calculate a proration" do
        @calculator.price = 31 #adjusting for simplicity
        assert_equal 17, @calculator.prorate_from(Date.parse('15/1/2012'))  
      end
    end

    context "from a date equal to the anniversary date the proration" do
      should "be the full price" do
        assert_equal @price, @calculator.prorate_from(@anniversary_date)
      end
    end

    context "from a date posterior to the anniversary date the proration" do
      should "be calculated just fine" do
        assert_equal 14, @calculator.prorate_from(Date.parse('15/2/2012'))
      end

      should "return the full price if the future date is the next anniversary date" do
        assert_equal 29, @calculator.prorate_from(Date.parse('1/3/2012'))
      end
    end

  end
  context "calculating a yearly proration" do
    setup do
      @anniversary_date = Date.parse('1/1/2013')
      @cycle = BillingCycle.new(period: :year, 
                                frequency: 1, 
                                anniversary: @anniversary_date)
      @price = 36600
      @calculator = ProrationCalculator.new(billing_cycle: @cycle, 
                                            price: @price)
    end
    should "calculate a proration of $350 on the 1/16" do
      @calculator.date = Date.parse('16/1/2012')
      assert_equal 35100, @calculator.prorate
    end
  end
end
