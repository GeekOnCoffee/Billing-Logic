module BillingLogic::Strategies

  class SinglePaymentStrategy < BaseStrategy

    def default_command_builder
      BillingLogic::CommandBuilders::AggregateWordBuilder
    end

    def add_commands_for_products_to_be_added
      unless products_to_be_added.empty?
        products_to_be_added.each do |group_of_products, date|
          @command_list << create_recurring_payment_command(group_of_products, 
                                                            :next_payment_date => date,
                                                            :period => extract_period_from_product_list(group_of_products))
        end
      end
    end

    def proration_for_product(product)
      BillingLogic::ProrationCalculator.new(:billing_cycle => product.billing_cycle,
                                            :price => product.price,
                                            :date   => today + 1 ).prorate
    end

    def update_product_billing_cycle_and_payment!(product, previous_product)
      if product.billing_cycle.periodicity > previous_product.billing_cycle.periodicity
        product.initial_payment = product.price - proration_for_product(previous_product)
        product.billing_cycle.anniversary = today
      end
    end

    def next_payment_date_from_product(product, previous_product)
      if product.billing_cycle.periodicity > previous_product.billing_cycle.periodicity
        product.billing_cycle.next_payment_date
      else
        next_payment_date_from_profile_with_product(product, :active => true)
      end
    end

  end
end
