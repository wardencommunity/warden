$TESTING=true
$:.push File.join(File.dirname(__FILE__), '..', 'lib')
require 'rubygems'
require 'rack'
require 'rack-auth'

Dir[File.join(File.dirname(__FILE__), "rack-auth", "strategies", "**/*.rb")].each do |f|
  require f
end
Dir[File.join(File.dirname(__FILE__), "helpers", "**/*.rb")].each do |f|
  require f
end

Spec::Runner.configure do |config|
  config.include(Rack::Auth::Spec::Helpers)
end