module BillingLogic
  class SinglePaymentStrategy < IndependentPaymentStrategy

    def refund_recurring_payments_command(profile_id, amount)
      payment_command_builder_class.refund_recurring_payments_command(profile_id, amount)
    end

    def disable_subscription(profile_id)
      payment_command_builder_class.disable_subscription(profile_id)
    end

    # these messages seems like they should be pluggable
    def cancel_recurring_payment_command(profile_id)
      payment_command_builder_class.cancel_recurring_payment_commands(profile_id)
    end

    def add_commands_for_products_to_be_added
      unless products_to_be_added.empty?
        products_to_be_added.each do |group_of_product, date|
          @command_list << create_recurring_payment_command(group_of_product, date)
        end
      end
    end

    def create_recurring_payment_command(products, next_payment_date = Date.today)
      payment_command_builder_class.
        create_recurring_payment_commands(products,
                                          :next_payment_date => next_payment_date, 
                                          :period => products.first.billing_cycle.period)
    end

  end
end
