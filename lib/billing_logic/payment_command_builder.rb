module BillingLogic
  class PaymentCommandBuilder
    def initialize(products)
      @products = products
    end

    def group_products_by_billing_cycle
      @products.inject({}) do |a, e|
        a[e.billing_cycle] ||= []
        a[e.billing_cycle] << e
        a
      end
    end

    class << self
      def create_recurring_payment_commands(products, next_payment_date = Date.today)
        self.new(products).group_products_by_billing_cycle.map do |k, prods|
          {
            :action => 'create_recurring_payment',
            :products => prods,
            :price => prods.inject(0) { |a, e| a + e.price; a },
            :next_payment_date => next_payment_date,
            :billing_cycle => k
          }
        end
      end

      def cancel_recurring_payment_commands(*profile_ids)
        profile_ids.map do |profile_id| 
          {
            :action => :cancel_recurring_payment,
            :payment_profile_id => profile_id
          }
        end
      end
    end

  end
end
