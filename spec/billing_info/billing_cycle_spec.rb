require 'spec_helper'

describe BillingLogic::BillingCycle do
  context "a billing cycle" do
    before do 
      @cycle_45_days      = BillingLogic::BillingCycle.new(:period => :day,       :frequency => 45)
      @one_day_cycle      = BillingLogic::BillingCycle.new(:period => :day,       :frequency => 1)
      @one_week_cycle     = BillingLogic::BillingCycle.new(:period => :week,      :frequency => 1)
      @semimonth_cycle    = BillingLogic::BillingCycle.new(:period => :semimonth, :frequency => 1)
      @one_month_cycle    = BillingLogic::BillingCycle.new(:period => :month,     :frequency => 1)
      @one_year_cycle     = BillingLogic::BillingCycle.new(:period => :year,      :frequency => 1)
    end

    it "should know about its period type" do
      @cycle_45_days.period.should == :day
    end

    it "should know about its frequency" do
      @cycle_45_days.frequency.should == 45
    end

    it "should be able to calculate its periodicity" do
      @cycle_45_days.periodicity.should == 45
      @one_year_cycle.periodicity.should == 365
    end

    it "should know how to compare itself" do
      @one_day_cycle.should   < @one_week_cycle
      @one_week_cycle.should  < @semimonth_cycle
      @semimonth_cycle.should < @one_month_cycle
      @one_month_cycle.should < @cycle_45_days
      @cycle_45_days.should   < @one_year_cycle 
    end
  end
end
