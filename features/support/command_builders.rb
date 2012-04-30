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

  class WordBuilder
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

      def cancel_recurring_payment_commands(*profile_ids)
        profile_ids.map do |profile_id|
          "cancel #{profile_id} now"
        end
      end

      def refund_recurring_payments_command(profile_id, amount)
        "refund $#{amount} to #{profile_id} now"
      end

      def disable_subscription(profile_id)
        "disable #{profile_id} now"
      end
    end
  end

  class AggregateWordBuilder
    class << self
      include CommandBuilders::BuilderHelpers
      def create_recurring_payment_commands(products, opts = {:next_payment_date => Date.today, :price => nil, :frequency => 1, :period => nil})
        product_ids = products.map { |product| product.id }.join(' & ')
        price = opts[:price] || products.inject(0){ |k, product| k += product.price.to_i; k }
        initial_payment = opts[:initial_payment] || products.map { |product| product.initial_payment || 0 }.reduce(0) { |a, e| a + e }
        initial_payment_string = initial_payment.zero? ? '' : " with initial payment set to $#{initial_payment.to_i}"
        "add (#{product_ids}) @ $#{price}#{periodicity_abbrev(opts[:period])} on #{opts[:next_payment_date].strftime('%m/%d/%y')}#{initial_payment_string}"
      end

      def cancel_recurring_payment_commands(*profile_ids)
        profile_ids.map do |profile_id|
          "cancel #{profile_id} now"
        end
      end

      def refund_recurring_payments_command(profile_id, amount)
        "refund $#{amount} to #{profile_id} now"
      end

      def disable_subscription(profile_id)
        "disable #{profile_id} now"
      end
    end
  end

end
