require 'spec_helper'
module BillingLogic
  describe PaymentCommandBuilder do
    let(:monthly_cycle) do
          BillingCycle.new(:period => :month, 
                           :frequency => 1,
                           :anniversary => Date.today - 7)
    end

    let(:yearly_cycle) do
      BillingCycle.new(:period => :year, 
                       :frequency => 1,
                       :anniversary => Date.today - 7)
    end
    let(:product_a) { mock('Product A', :name => 'A', :price => 10, :billing_cycle => monthly_cycle) }
    let(:product_b) { mock('Product B', :name => 'B', :price => 10, :billing_cycle => monthly_cycle) }
    let(:yearly_product) { mock('Product Yearly', :name => 'Yearly', :price => 10, :billing_cycle => yearly_cycle) }

    describe "#group_products_by_billing_cycle" do
      context "when 1 billing cycle is present" do
        it "should return an array with 1 element" do
          builder = PaymentCommandBuilder.new([product_a])
          builder.group_products_by_billing_cycle.size.should == 1
        end

        it "should return an array with 1 element even if it has 2 different products" do
          builder = PaymentCommandBuilder.new([product_a, product_b])
          builder.group_products_by_billing_cycle.size.should == 1
        end
      end

      context "when 2 different billing cycle is present" do
        it "should return an array with 1 element" do
          builder = PaymentCommandBuilder.new([product_a, yearly_product])
          builder.group_products_by_billing_cycle.size.should == 2
        end
      end
    end

  end
end
