# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "warden/version"

Gem::Specification.new do |s|
  s.name        = "warden"
  s.version     = Warden::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Rack middleware that provides authentication for rack applications"
  s.email       = "has.sox@gmail.com"
  s.homepage    = "http://github.com/hassox/warden"
  s.authors     = ["Daniel Neighman", "José Valim"]

  s.rubyforge_project = "warden"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rack", ">= 1.0.0"
  s.add_development_dependency "rspec", "~> 1"
end
