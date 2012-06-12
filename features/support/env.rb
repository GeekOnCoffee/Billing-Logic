require 'cucumber/rspec/doubles'
require 'timecop'
require 'ostruct'

require_relative './helpers.rb'
require_relative '../../lib/billing_logic.rb'

World(Rspec::Matchers)
World(CancellationPolicyHelpers)
World(ProductPaymentHelpers)
World(StringParsers)
World(StrategyHelper)
