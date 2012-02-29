module BillingLogic
  class ProrationCalculator
    attr_accessor :billing_cycle, :price, :date
    def initialize(opts = {})
      self.billing_cycle = opts[:billing_cycle]
      self.price = opts[:price]
      self.date  = opts[:date]
    end

    def prorate_from(date = self.date)
      return price if date == self.billing_cycle.anniversary
      average_daily_price_for_billing_cycle(date) * distance_from_date_in_days(date)
    end
    alias :prorate :prorate_from

    def distance_from_date_in_days(date = self.date)
      (date - self.billing_cycle.anniversary).abs
    end

    def average_daily_price_for_billing_cycle(date = self.date)
      (self.price / (self.billing_cycle.days_in_billing_cycle_including(date)))
    end

  end
end
