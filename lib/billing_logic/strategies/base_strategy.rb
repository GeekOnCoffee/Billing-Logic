module BillingLogic
  class BaseStrategy
    attr_accessor :desired_state, :current_state, :payment_command_builder_class
    def initialize(opts = {})
      self.current_state = opts.delete(:current_state) || []
      @desired_state = opts.delete(:desired_state) || []
      @command_list = []
      @payment_command_builder_class = opts.delete(:payment_command_builder_class) || PaymentCommandBuilder
    end

    def command_list
      calculate_list
      @command_list.flatten
    end

    def current_state=(subscriptions)
      @current_state = removed_obsolete_subscriptions(subscriptions)
    end

    def removed_obsolete_subscriptions(subscriptions)
      subscriptions.reject{|sub| sub.next_payment_date < today }
    end

    def calculate_list
      reset_command_list
      add_commands_for_products_to_be_added
      add_commands_for_products_to_be_removed
    end

    def add_commands_for_products_to_be_added
    end

    # Question:
    # Should the method return a data structure or an object?
    def products_to_be_added
      new_products = desired_state.reject do |product|
        ProductComparator.new(product).in_like?(current_active_or_pending_products)
      end
      group_by_date(new_products)
    end

    # this doesn't feel like it should be here
    def group_by_date(new_products)
      group = {}
      new_products.each do |product|
        if previously_cancelled_product?(product)
          date = next_payment_date_from_profile_with_product(product, :active => false)
        elsif previous_product = changed_product_subscription?(product)
          date = next_payment_date_from_product(product, previous_product)
        else
          date = today
        end
        group[date] ||= []
        group[date] << product
      end
      group.map { |k, v| [v, k] } 
    end

    def previously_cancelled_product?(product)
      inactive_products.detect do |inactive_product| 
        ProductComparator.new(inactive_product).same_class?(product) 
      end
    end

    def changed_product_subscription?(product)
      products_to_be_removed.detect do |removed_product|
        ProductComparator.new(removed_product).same_class?(product) 
      end
    end

    def next_payment_date_from_profile_with_product(product, opts = {:active => false})
      profiles_by_status(opts[:active]).map do |profile|
        profile.next_payment_date if ProductComparator.new(product).in_class_of?(profile.products)
      end.compact.max
    end

    def next_payment_date_from_product(product, previous_product)
      product.initial_payment = product.price
      product.billing_cycle.anniversary = next_payment_date_from_profile_with_product(product, :active => true) #previous_product.billing_cycle.next_payment_date
      product.billing_cycle.closest_anniversary_date_including(product.billing_cycle.anniversary)
    end

    # for easy stubbing/subclassing/replacement
    def today
      Date.today
    end

    def products_to_be_removed
      current_active_or_pending_products.reject do |product|
        ProductComparator.new(product).included?(desired_state)
      end
    end

    def current_products(opts = {})
      profiles_by_status(opts[:active]).map { |profile| profile.products }.flatten
    end

    def profiles_by_status(active_or_pending = nil)
      current_state.reject { |profile| !profile.active_or_pending? == active_or_pending}
    end

    def inactive_products
      current_products(:active => false)
    end

    def current_active_or_pending_products
      current_products(:active => true)
    end

    # this should be part of a separate strategy object
    def add_commands_for_products_to_be_removed
      # puts "\n ### \n #{current_state} \n\####"
      current_state.each do |profile|
        # We need to issue refunds before cancelling profiles
        @command_list << issue_refunds_if_necessary(profile)
        remaining_products = remove_products_from_profile(profile)
        if remaining_products.empty? # all products in payment profile needs to be removed
          @command_list << cancel_recurring_payment_command(profile.id)
        elsif remaining_products.size == profile.products.size # nothing has changed
          # do nothing
        else  # only some products are being removed and the profile needs to be updated
          @command_list << cancel_recurring_payment_command(profile.id)
          @command_list << create_recurring_payment_command(remaining_products, :next_payment_date => profile.next_payment_date,
                                                           :period => extract_period_from_product_list(remaining_products))
        end
      end
    end

    def extract_period_from_product_list(products)
      products.first.billing_cycle.period
    end

    def remove_products_from_profile(profile)
      profile.products.reject { |product| products_to_be_removed.include?(product) }
    end

    def issue_refunds_if_necessary(profile)
      ret = []
      profile.products.find_all{ |product| products_to_be_removed.include?(product) }.map do |refunded_product|
        if profile.last_payment_refundable?
          ret << refund_recurring_payments_command(profile.id, profile.last_payment_amount)
          ret << disable_subscription(profile.id)
        end
      end
      ret
    end

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

    def create_recurring_payment_command(products, opts = {:next_payment_date => Date.today})
      payment_command_builder_class.create_recurring_payment_commands(products, opts)
    end

    def reset_command_list
      @command_list.clear
    end

    class ProductComparator
      extend Forwardable
      def_delegators :@product, :name, :price, :billing_cycle
      def initialize(product)
        @product = product
      end

      def included?(product_list)
        product_list.any? { |product| ProductComparator.new(product).similar?(self) }
      end

      def in_class_of?(product_list)
        product_list.any? { |product| ProductComparator.new(product).same_class?(self) }
      end

      def in_like?(product_list)
        product_list.any? { |product| ProductComparator.new(product).like?(self) }
      end

      def like?(other_product)
        similar?(other_product) && same_periodicity?(other_product)
      end

      def similar?(other_product)
        same_class?(other_product) &&  same_price?(other_product)
      end

      def same_periodicity?(other_product)
        @product.billing_cycle.periodicity == other_product.billing_cycle.periodicity
      end

      def same_class?(other_product)
        @product.name == other_product.name
      end

      def same_price?(other_product)
        @product.price == other_product.price
      end
    end

  end
end
