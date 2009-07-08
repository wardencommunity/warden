require 'rubygems'
require 'rack'
require 'spec/rake/spectask'

GEM = "warden"
GEM_VERSION = "0.2.1"
AUTHORS = ["Daniel Neighman"]
EMAIL = "has.sox@gmail.com"
HOMEPAGE = "http://github.com/hassox/warden"
SUMMARY = "Rack middleware that provides authentication for rack applications"

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = GEM
    gem.summary = SUMMARY
    gem.email = EMAIL
    gem.homepage = HOMEPAGE
    gem.authors = AUTHORS
    gem.rubyforge_project = "warden"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
 
    gem.add_dependency "rack", ">= 1.0.0"
  end
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = %w(-fs --color)
end
