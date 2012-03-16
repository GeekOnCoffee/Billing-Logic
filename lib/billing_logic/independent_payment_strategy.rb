module BillingLogic
  class IndependentPaymentStrategy
    attr_accessor :desired_state, :current_state, :payment_command_builder_class
    def initialize(opts = {})
      @current_state = opts.delete(:current_state) || []
      @desired_state = opts.delete(:desired_state) || []
      @command_list = []
      @payment_command_builder_class = opts.delete(:payment_command_builder_class) || PaymentCommandBuilder
    end

    def desired_state=(value)
      @desired_state = value
    end

    def command_list
      calculate_list
      @command_list.flatten
    end

    def calculate_list
      reset_command_list
      add_commands_for_products_to_be_added
      add_commands_for_products_to_be_removed
    end

    def add_commands_for_products_to_be_added
      unless products_to_be_added.empty?
        products_to_be_added.each do |group_of_product, date|
          @command_list << create_recurring_payment_command(group_of_product, date)
        end
      end
    end

    # Question:
    # Should the method return a data structure or an object?
    def products_to_be_added
      group_by_date(desired_state - current_active_or_pending_products)
    end

    # this doesn't feel like it should be here
    def group_by_date(new_products)
      group = {}
      new_products.each do |product|
        if inactive_products.include?(product)
          next_payment_dates = profiles_by_status(active_or_pending = false).select { |profile| profile.products.include?(product) }.map { |profile| profile.next_payment_date }
          next_payment_date = next_payment_dates.sort.first
          group[next_payment_date] ||= []
          group[next_payment_date] << product
        else
          group[today] ||= []
          group[today] << product
        end
      end
      group.map { |k, v| group.assoc(k).reverse } 
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
        remaining_products = profile.products.reject { |product| products_to_be_removed.include?(product) }
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

