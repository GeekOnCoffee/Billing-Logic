require 'spec_helper'
module Helper
  def self.date(d)
    Date.strptime(d, '%d/%m/%Y')
  end
end
module BillingLogic
  
  describe ProrationCalculator do
    context "calculating monthly prorations" do
      before do
        @anniversary_date = Helper.date('1/2/2012')
        @cycle = BillingCycle.new(:period => :month, 
                                  :frequency => 1, 
                                  :anniversary => @anniversary_date)
        @price = 29.0 
        @calculator = ProrationCalculator.new(:billing_cycle => @cycle, 
                                              :price => @price)
      end
      it "should recall price & cycles" do
        @calculator.price.should == @price
        @calculator.billing_cycle.should == @cycle
      end

      context "from a date prior to the anniversary date" do
        it "should be able to calculate a proration" do
          @calculator.price = 31 #adjusting for simplicity
          @calculator.prorate_from(Helper.date('15/1/2012')).should == 17
        end
      end

      context "from a date equal to the anniversary date the proration" do
        it "should be the full price" do
          @calculator.prorate_from(@anniversary_date).should == @price
        end
      end

      context "from a date posterior to the anniversary date the proration" do
        it "should be calculated just fine" do
          @calculator.prorate_from(Helper.date('15/2/2012')).should == 14
        end

        it "should return the full price if the future date is the next anniversary date" do
          @calculator.prorate_from(Helper.date('1/3/2012')).should == 29
        end
      end

    end
    context "calculating a yearly proration" do
      before do
        @anniversary_date = Helper.date('1/1/2013')
        @cycle = BillingCycle.new(:period => :year, 
                                  :frequency => 1, 
                                  :anniversary => @anniversary_date)
        @price = 36600
        @calculator = ProrationCalculator.new(:billing_cycle => @cycle, 
                                              :price => @price)
      end
      it "should calculate a proration of $350 on the 1/16" do
        @calculator.date = Helper.date('16/1/2012')
        @calculator.prorate.should == 35100
      end
    end
  end
end
