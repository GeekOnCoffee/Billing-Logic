require "bundler/gem_tasks"
require 'rake'
require 'rake/testtask'
require 'rake/packagetask'
require 'rubygems/package_task'
require 'rspec/core/rake_task'
require 'cucumber/rake/task'

RSpec::Core::RakeTask.new('spec')
task :default => :ci

desc "run specs & cucumbers"
task :ci => [:spec, :cucumber]

desc 'Run integration test'
Cucumber::Rake::Task.new do |t|
  output = ENV['CC_BUILD_ARTIFACTS'] || "./log"
  t.cucumber_opts = ["--format html --out #{output}/cukes.html", "-f pretty"]
end
