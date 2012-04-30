# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "billing_logic/version"

Gem::Specification.new do |s|
  s.name        = "billing_logic"
  s.version     = BillingLogic::VERSION
  s.authors     = ["Diego Scataglini"]
  s.email       = ["diego@junivi.com"]
  s.homepage    = ""
  s.summary     = %q{The only recurring billing logic you'll need}
  s.description = %q{There are only a few way to calculate prorations & manage recurring payments.}

  s.rubyforge_project = "billing_logic"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
