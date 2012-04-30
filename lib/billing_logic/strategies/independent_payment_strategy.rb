module BillingLogic
  class IndependentPaymentStrategy < BaseStrategy
    
    def add_commands_for_products_to_be_added
      unless products_to_be_added.empty?
        products_to_be_added.each do |group_of_products, date|
          group_of_products.each do |products|
            @command_list << create_recurring_payment_command([products], :next_payment_date => date)
          end
        end
      end
    end

  end
end

