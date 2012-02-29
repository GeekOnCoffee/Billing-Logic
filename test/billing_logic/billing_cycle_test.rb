require File.expand_path(File.dirname(__FILE__) + '/../helper')

class BillingCycleTest < Test::Unit::TestCase
  include BillingLogic
  context "a billing cycle" do
    setup do 
      @cycle_45_days      = BillingCycle.new(:period => :day,       :frequency => 45)
      @one_day_cycle      = BillingCycle.new(:period => :day,       :frequency => 1)
      @one_week_cycle     = BillingCycle.new(:period => :week,      :frequency => 1)
      @semimonth_cycle    = BillingCycle.new(:period => :semimonth, :frequency => 1)
      @one_month_cycle    = BillingCycle.new(:period => :month,     :frequency => 1)
      @one_year_cycle     = BillingCycle.new(:period => :year,      :frequency => 1)
    end

    should "know about its period type" do
      assert_equal :day, @cycle_45_days.period
    end

    should "know about its frequency" do
      assert_equal 45, @cycle_45_days.frequency
    end

    should "be able to calculate its periodicity" do
      assert_equal 45, @cycle_45_days.periodicity
      assert_equal 364, @one_year_cycle.periodicity
    end

    should "know how to compare itself" do
      assert @one_day_cycle   < @one_week_cycle
      assert @one_week_cycle  < @semimonth_cycle
      assert @semimonth_cycle < @one_month_cycle
      assert @one_month_cycle < @cycle_45_days
      assert @cycle_45_days   < @one_year_cycle 
    end
  end
end
