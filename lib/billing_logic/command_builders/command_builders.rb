module BillingLogic
  module CommandBuilders
    SINGLE_PRODUCT_REGEX = '(\w+) @ \$([\d\.]+)(\/mo|\/yr)?'
    DATE_REGEX  = '(\d{1,2}\/\d{1,2}\/\d{2,4})'
    MONEY_REGEX = '\$([\d\.]+)'

    module BuilderHelpers
      def self.money(money)
        "%01.2f" % Float(money)
      end
    end

    class ProductList
      def self.parse(string, options = {})
        if (products = (string =~ /\(([^\(\)]*)\)/) ? $1 : nil)
          products.split(/ & /).map do |product_string|
            ProductStub.parse(product_string, options)
          end
        else
          []
        end
      end
    end

    class ProductStub
      attr_accessor :name, :price, :identifier, :billing_cycle, :payments, :initial_payment
      def self.parse(string, options = {})
        string =~ /#{BillingLogic::CommandBuilders::SINGLE_PRODUCT_REGEX}/
        billing_cycle = $3 ? ::BillingLogic::BillingCycle.new(:frequency => 1, :period => $3.include?('mo') ? :month : :year) : nil
        product = (options[:product_class] || self).new
        product.name = $1
        product.price = Float($2)
        product.identifier = "#{$1} @ $#{$2}#{$3}"
        product.billing_cycle = billing_cycle
        product.initial_payment = 0
        product
      end

    end

    class ActionObject
      attr_accessor :action, :products, :profile_id, :initial_payment, :disable, :refund, :starts_on

      def initialize(opts = {})
        @action           = opts[:action]
        @profile_id       = opts[:profile_id]
        @products         = opts[:products]
        @disable          = opts[:disable]
        @refund           = opts[:refund]
        @initial_payment  = opts[:initial_payment]
        @starts_on        = opts[:starts_on]
        @price            = opts[:price]
      end

      def to_s
        case action
        when :cancel
          "cancel #{'and disable ' if disable}[#{profile_id}] #{"with refund $#{BuilderHelpers.money(refund)} " if refund}now"
        when :remove
          "remove (#{products.map { |product| product.identifier }.join(" & ")}) from [#{profile_id}] #{"with refund $#{BuilderHelpers.money(refund)}" if refund}now"
        when :add
          products.map do |product|
            initial_payment_string = total_initial_payment.zero? ? '' : " with initial payment set to $#{BuilderHelpers.money(total_initial_payment)}"
            "add (#{product.identifier}) on #{starts_on.strftime('%m/%d/%y')}#{initial_payment_string}"
          end.to_s
        when :add_bundle
          product_ids = products.map { |product| product.identifier }.join(' & ')
          price ||= products.inject(0){ |k, product| k += product.price; k }
          price_string = BuilderHelpers.money(price)
          initial_payment_string = total_initial_payment.zero? ? '' : " with initial payment set to $#{BuilderHelpers.money(total_initial_payment)}"
          "add (#{product_ids}) @ $#{price_string}#{periodicity_abbrev(products.first.billing_cycle.period)} on #{starts_on.strftime('%m/%d/%y')}#{initial_payment_string}"
        end
      end

      def self.from_string(string, options = {:product_class => ProductStub})
        opts = {}
        opts[:action]     = case string
                            when /^add \(.*\) @/
                              :add_bundle
                            when /^(cancel|remove|add)/
                              $1.to_sym
                            end
        opts[:disable]    = !!(string =~ /and disable/)
        opts[:starts_on]  = (string =~ /on #{BillingLogic::CommandBuilders::DATE_REGEX}/) ? Date.strptime($1, '%m/%d/%y') : (string =~ /now$/) ? Time.now : nil
        opts[:products] = ProductList.parse(string, options)

        opts[:profile_id] = case opts[:action]
                            when :cancel, :remove
                              string =~ /\[(.*)\]/ ? $1 : nil
                            end
        opts[:refund]     = (string =~ /with refund #{BillingLogic::CommandBuilders::MONEY_REGEX}/) ? Float($1) : nil
        opts[:initial_payment] = (string =~ /with initial payment set to #{BillingLogic::CommandBuilders::MONEY_REGEX}/) ? Float($1) : nil
        opts[:price]      = (string =~ /add \(.*\) @ #{BillingLogic::CommandBuilders::MONEY_REGEX}/) ? Float($1) : nil

        self.new(opts)
      end

      def total_initial_payment
        @initial_payment ||= products.map { |product| product.initial_payment || 0 }.reduce(0) { |a, e| a + e }
      end
      
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
        def create_recurring_payment_commands(products, opts = {:paid_until_date => Date.today})
          raise Exception.new('Implement me')
        end

        # override this with Time.zone if used with rails
        def time
          Time
        end

        def cancel_recurring_payment_commands(profile, opts = {})
          ActionObject.new(opts.merge(:action     => :cancel,
                                      :profile_id => profile.identifier,
                                      :products   => profile.products,
                                      :when       => time.now))
        end

        def remove_product_from_payment_profile(profile_id, products, opts)
          ActionObject.new(opts.merge(:action     => :remove,
                                      :products   => products,
                                      :profile_id => profile_id,
                                      :when       => time.now))
        end
      end
    end

    class WordBuilder < BasicBuilder
      class << self
        def create_recurring_payment_commands(products, opts = {:paid_until_date => Date.today})
          ActionObject.new(opts.merge(:action     => :add,
                                      :products   => products,
                                      :starts_on  => opts[:paid_until_date],
                                      :when       => time.now))
        end
      end
    end

    class AggregateWordBuilder < BasicBuilder
      class << self
        include CommandBuilders::BuilderHelpers
        def create_recurring_payment_commands(products, opts = {:paid_until_date => Date.today, :price => nil, :frequency => 1, :period => nil})
          ActionObject.new(opts.merge(:action     => :add_bundle,
                                      :products   => products,
                                      :starts_on  => opts[:paid_until_date],
                                      :when       => time.now))
          
        end
      end
    end
  end

end

