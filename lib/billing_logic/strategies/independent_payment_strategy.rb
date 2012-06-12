module BillingLogic::Strategies
  class IndependentPaymentStrategy < BaseStrategy

    def default_command_builder
      BillingLogic::CommandBuilders::WordBuilder
    end

    def add_commands_for_products_to_be_added!
      with_products_to_be_added do |group_of_products, date|
        group_of_products.each do |products|
          @command_list << create_recurring_payment_command([products], :paid_until_date => date)
        end
      end
    end

  end
end

