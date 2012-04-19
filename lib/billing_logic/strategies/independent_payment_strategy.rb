module BillingLogic
  class IndependentPaymentStrategy
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
      subscriptions.reject{|sub| sub.next_payment_date < Date.today }
    end

    def calculate_list
      reset_command_list
      add_commands_for_products_to_be_added
      add_commands_for_products_to_be_removed
    end

    def add_commands_for_products_to_be_added
      unless products_to_be_added.empty?
        products_to_be_added.each do |group_of_product, date|
          group_of_product.each do |product|
            @command_list << create_recurring_payment_command([product], date)
          end
        end
      end
    end

    # Question:
    # Should the method return a data structure or an object?
    def products_to_be_added
      new_products = desired_state.reject do |el|
        current_active_or_pending_products.map{|el| el.name}.include?(el.name) &&
          el.billing_cycle.periodicity  == current_active_or_pending_products.detect{|cael| cael.name == el.name}.billing_cycle.periodicity
      end
      group_by_date(new_products)
    end

    # this doesn't feel like it should be here
    def group_by_date(new_products)
      group = {}
      new_products.each do |product|
        if inactive_products.map{|prod| prod.name}.include?(product.name)
          date = next_payment_date_from_profile_with_product(product)
        elsif current_active_or_pending_products.map{|prod2| prod2.name}.include?(product.name)
          date = next_payment_date_from_profile_with_product(product, :active => true)
        else
          date = today
        end
        group[date] ||= []
        group[date] << product
      end
      group.map { |k, v| group.assoc(k).reverse } 
    end

    def next_payment_date_from_profile_with_product(product, opts = {:active => false})
      profiles_by_status(opts[:active]).select do |profile| 
        profile.products.map{|product| product.name}.include?(product.name)
      end.map do |profile| 
        profile.next_payment_date 
      end.sort.first
    end

    # for easy stubbing/subclassing/replacement
    def today
      Date.today
    end

    def products_to_be_removed
      current_active_or_pending_products - desired_state
    end

    def current_products(opts = {})
      profiles_by_status(opts[:active]).map { |profile| profile.products }.flatten
    end

    def profiles_by_status(active_or_pending = nil)
      current_state.reject { |profile| !profile.active_or_pending? == active_or_pending}
    end

    def inactive_products
      current_products(active: false)
    end

    def current_active_or_pending_products
      current_products(active: true)
    end

    # this should be part of a separate strategy object
    def add_commands_for_products_to_be_removed
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
          @command_list << create_recurring_payment_command(remaining_products, profile.next_payment_date)
        end
      end
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

    def create_recurring_payment_command(products, next_payment_date = Date.today)
      payment_command_builder_class.create_recurring_payment_commands(products, next_payment_date)
    end

    def reset_command_list
      @command_list.clear
    end

  end
end

