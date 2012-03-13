require 'spec_helper'

describe BillingLogic::ProrationCalculator do
  include BillingLogic
  context "calculating monthly prorations" do
    before do
      @anniversary_date = Date.parse('1/2/2012')
      @cycle = BillingCycle.new(period: :month, 
                                frequency: 1, 
                                anniversary: @anniversary_date)
      @price = 29.0 
      @calculator = ProrationCalculator.new(billing_cycle: @cycle, 
                                            price: @price)
    end
    it "recall price & cycles" do
      @calculator.price.should == @price
      @calculator.billing_cycle.should == @cycle
    end

    context "from a date prior to the anniversary date" do
      it "be able to calculate a proration" do
        @calculator.price = 31 #adjusting for simplicity
        @calculator.prorate_from(Date.parse('15/1/2012')).should == 17
      end
    end

    context "from a date equal to the anniversary date the proration" do
      it "be the full price" do
        @calculator.prorate_from(@anniversary_date).should == @price
      end
    end

    context "from a date posterior to the anniversary date the proration" do
      it "be calculated just fine" do
        @calculator.prorate_from(Date.parse('15/2/2012')).should == 14
      end

      it "return the full price if the future date is the next anniversary date" do
        @calculator.prorate_from(Date.parse('1/3/2012')).should == 29
      end
    end

  end
  context "calculating a yearly proration" do
    before do
      @anniversary_date = Date.parse('1/1/2013')
      @cycle = BillingCycle.new(period: :year, 
                                frequency: 1, 
                                anniversary: @anniversary_date)
      @price = 36600
      @calculator = ProrationCalculator.new(billing_cycle: @cycle, 
                                            price: @price)
    end
    it "calculate a proration of $350 on the 1/16" do
      @calculator.date = Date.parse('16/1/2012')
      @calculator.prorate.should == 35100
    end
  end
end
