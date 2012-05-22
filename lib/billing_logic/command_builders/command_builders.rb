module BillingLogic
  module CommandBuilders
    module BuilderHelpers
      protected
      def periodicity_abbrev(period)
        case period
        when :year; '/yr'
        when :month;'/mo'
        when :week; '/wk'
        when :day;  '/day'
        else
          period
        end
      end
    end
    class BasicBuilder
      class << self
        def create_recurring_payment_commands(products, opts = {:next_payment_date => Date.today})
          raise Exception.new('Implement me')
        end

        def cancel_recurring_payment_commands(profile_id, opts = {})
          "cancel #{'and disable ' if opts[:disable]}#{profile_id} #{"with refund $#{opts[:refund]} " if opts[:refund]}now"
        end

        def refund_recurring_payments_command(profile_id, amount)
          "refund $#{amount} to #{profile_id} now"
        end

        def disable_subscription(profile_id)
          "disable #{profile_id} now"
        end

        def remove_product_from_payment_profile(profile_id, products, opts)
          "remove #{products.map { |product| product.id }.join(" & ")} from #{profile_id} #{"with refund $#{opts[:refund]}" if opts[:refund]}now"
        end
      end
    end

    class WordBuilder < BasicBuilder
      class << self
        def create_recurring_payment_commands(products, opts = {:next_payment_date => Date.today})
          products.map do |product|
            initial_payment_string = product.initial_payment.zero? ? '' : " with initial payment set to $#{product.initial_payment}" 
            if product.billing_cycle.frequency == 1
              "add #{product.id} on #{opts[:next_payment_date].strftime('%m/%d/%y')}#{initial_payment_string}"
            else
              "add #{product.id} on #{opts[:next_payment_date].strftime('%m/%d/%y')} renewing every #{product.billing_cycle.frequency} #{product.billing_cycle.period}#{initial_payment_string}"
            end
          end
        end
      end
    end

    class AggregateWordBuilder < BasicBuilder
      class << self
        include CommandBuilders::BuilderHelpers
        def create_recurring_payment_commands(products, opts = {:next_payment_date => Date.today, :price => nil, :frequency => 1, :period => nil})
          product_ids = products.map { |product| product.id }.join(' & ')
          price = opts[:price] || products.inject(0){ |k, product| k += product.price.to_i; k }
          initial_payment = opts[:initial_payment] || products.map { |product| product.initial_payment || 0 }.reduce(0) { |a, e| a + e }
          initial_payment_string = initial_payment.zero? ? '' : " with initial payment set to $#{initial_payment.to_i}"
          "add (#{product_ids}) @ $#{price}#{periodicity_abbrev(opts[:period])} on #{opts[:next_payment_date].strftime('%m/%d/%y')}#{initial_payment_string}"
        end
      end
    end
  end

end
