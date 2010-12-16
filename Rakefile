require 'rubygems'
require 'rspec/core/rake_task'
require File.join(File.dirname(__FILE__), "lib", "warden", "version")

task :default => :spec

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = %w(-fs --color --backtrace)
end
