module BillingLogic
  class BillingCycle
    include Comparable
    attr_accessor :period, :frequency, :anniversary
    TIME_UNITS = { :day => 1, :week => 7, :month => 365/12.0, :semimonth=> 365/24, :year => 365 }

    def initialize(opts = {})
      self.period = opts[:period]
      self.frequency = opts[:frequency] || 1
      self.anniversary = opts[:anniversary]
    end

    def <=>(other)
      self.periodicity <=> other.periodicity
    end

    def periodicity
      time_unit_measure * frequency
    end

    def days_in_billing_cycle_including(date)
      (closest_anniversary_date_including(date) - anniversary).abs
    end

    def next_payment_date
      closest_anniversary_date_including(Date.today)
    end
    
    def closest_anniversary_date_including(date) 
      date_in_past = date < anniversary
      operators =   {:month => date_in_past ? :<< : :>>, 
                     :day   => date_in_past ? :-  : :+ }
      case self.period
      when :month
        anniversary.send(operators[:month], self.frequency)
      when :day, :semimonth, :week
        anniversary.send(operators[:day], self.periodicity)
      when :year
        anniversary.send(operators[:month], (self.frequency * 12))
      end
    end

    private
    def time_unit_measure
      TIME_UNITS[self.period]
    end

  end
end
