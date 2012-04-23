require 'spec_helper'

module BillingLogic
  describe IndependentPaymentStrategy do
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
    let(:product_b) { mock('Product B', :name => 'B', :price => 20, :billing_cycle => monthly_cycle) }
    let(:product_c) { mock('Product C', :name => 'C', :price => 30, :billing_cycle => monthly_cycle) }
    let(:product_d) { mock('Product D', :name => 'D', :price => 40, :billing_cycle => monthly_cycle) }
    let(:strategy)  { IndependentPaymentStrategy.new }


    let(:profile_a) do
      mock('Profile A', 
            :products => [product_a, product_b],
            :price => 30,
            :id => 'i-1',
            :next_payment_date => monthly_cycle.next_payment_date,
            :active_or_pending? => true,
            :last_payment_refundable? => false
           )
    end
    let(:canceled_profile_d) do
      mock('Profile D', 
            :products => [product_d],
            :price => 40,
            :id => 'i-4',
            :next_payment_date => monthly_cycle.next_payment_date,
            :active_or_pending? => false,
            :last_payment_refundable? => false
           )
    end

    let(:strategy_with_3_current_products) do
      IndependentPaymentStrategy.new(:current_state =>
                                       [profile_a,
                                        mock('Profile B', 
                                            :products => [product_c],
                                            :price => 30,
                                            :id => 'i-2',
                                            :active_or_pending? => true,
                                            :next_payment_date => monthly_cycle.next_payment_date,
                                            :last_payment_refundable? => false
                                            )
                                        ]
                                      )
    end

    describe "#current_products" do
      it "should return an array" do
        strategy.current_products.should be_kind_of(Array)
      end

      it "should return the products in the current state" do
        strategy_with_3_current_products.current_products.should == [product_a, product_b, product_c]
      end
    end

    describe "#products_to_be_added" do
      it "should not return products that are already in the current state" do
        strategy.current_state = []
        strategy.desired_state = []
        strategy.products_to_be_added.should be_empty
      end

      it "should return products that are not in the current state" do
        strategy.current_state = []
        strategy.desired_state = [product_a]
        strategy.products_to_be_added.should == [[[product_a], Date.today]]
      end
    end

    describe "#products_to_be_removed" do
      def products_to_names(products)
        products.map{|p| p.name}.joi(', ')
      end
      it "calculates correctly the products to be removed" do
        [
          {:profile => [profile_a], :desired_state => [product_a, product_b], :expected => []},
          {:profile => [profile_a], :desired_state => [product_a], :expected => [product_b]},
          {:profile => [profile_a], :desired_state => [product_c], :expected => [product_a, product_b]},
          {:profile => [profile_a], :desired_state => [], :expected => [product_a, product_b]},
          {:profile => [canceled_profile_d], :desired_state => [], :expected => []}
        ].each do |spec|
          strategy.current_state = spec[:profile]
          strategy.desired_state = spec[:desired_state]
          strategy.products_to_be_removed.should == spec[:expected]
        end
      end
    end


    context 'with empty current state' do
      let(:strategy) { IndependentPaymentStrategy.new }

      context 'with an empty desired state' do
        it 'should return an empty command list' do
          strategy.command_list.should == []
          strategy.command_list.should be_empty
        end
      end

      context 'with 1 new subscription in the desired state' do
        before do
          strategy.desired_state = [product_a]
        end

        it "should call create_recurring_payment_command with 1 product on the command builder object" do
          strategy.payment_command_builder_class.should_receive(:create_recurring_payment_commands).with([product_a], :next_payment_date => Date.today).once
          strategy.command_list
        end

        it 'should return 1 command in the command list' do
          strategy.command_list.size.should == 1
        end

      end

    end

    context 'with 2 current profile with 3 products' do
      context "when going towards a desired state of no products" do
        before do
          strategy_with_3_current_products.desired_state = []
        end

        # NOTE: this should be moved to a separate class
        it 'should know which product should be removed' do
          strategy_with_3_current_products.products_to_be_removed.should == [product_a, product_b, product_c]
        end
        
        it "should call :cancel_recurring_payment_command twice" do
          strategy_with_3_current_products.should_receive(:cancel_recurring_payment_command).twice
          strategy_with_3_current_products.command_list
        end
      end

      context "when removing a partial product from a profile" do
        before do 
          strategy_with_3_current_products.desired_state = [product_b, product_c]
        end

        it "should cancel the profile with the partial match" do
          strategy_with_3_current_products.should_receive(:cancel_recurring_payment_command).with('i-1').once
          strategy_with_3_current_products.command_list
        end

        it "should create a new profile with the remaining product at the end of of the current billing cycle" do
          strategy_with_3_current_products.should_receive(:create_recurring_payment_command).with([product_b], hash_including(:next_payment_date => profile_a.next_payment_date)).once
          strategy_with_3_current_products.command_list
        end
      end

      context "with a yearly subscription" do
        before do 
          profile_a.stub(:next_payment_date) { Date.today >> 12 }
          strategy.current_state = [profile_a]
        end

        it "should add monthly plan at the end of the year when switching to monthly cycle" do
          product_a.stub(:billing_cycle) { monthly_cycle }
          strategy.desired_state = [product_a]
          strategy.should_receive(:create_recurring_payment_command).with([product_a], hash_including(:next_payment_date => profile_a.next_payment_date)).once
          strategy.should_receive(:cancel_recurring_payment_command).with(profile_a.id).once
          strategy.command_list
        end

        context "that is cancelled and being re-added" do
          before do
            profile_a.stub(:active_or_pending?) { false }
            strategy.desired_state = [product_a]
          end

          it "shouldn't try to cancel the yearly subscription if already cancelled" do
            strategy.should_not_receive(:cancel_recurring_payment_command)
            strategy.command_list
          end

          it "should re-add the cancelled product at the end of the year" do
            strategy.should_receive(:create_recurring_payment_command).with([product_a], :next_payment_date => Date.today >> 12).once
            strategy.command_list
          end
        end
      end

      context "with one of them cancelled" do
        before do 
          strategy.current_state = [canceled_profile_d]
        end
        context "when re-adding the cancelled product" do
          it "should add it to the end of the cancelled period" do
            strategy.desired_state = [product_d]
            strategy.should_receive(:create_recurring_payment_command).with([product_d], :next_payment_date => canceled_profile_d.next_payment_date).once
            strategy.command_list
          end
        end

      end

      context "with one of them cancelled twice" do
        before do
          strategy.current_state = [canceled_profile_d, canceled_profile_d.clone]
        end

        context "when re-adding the cancelled product" do
          it "should add it to the end of the cancelled period" do
            strategy.desired_state = [product_d]
            strategy.should_receive(:create_recurring_payment_command).with([product_d], :next_payment_date => canceled_profile_d.next_payment_date).once
            strategy.command_list
          end
        end

      end

    end
  end
end
