# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{warden}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Daniel Neighman"]
  s.autorequire = %q{warden}
  s.date = %q{2009-04-26}
  s.description = %q{Rack middleware that provides authentication for rack applications}
  s.email = %q{has.sox@gmail.com}
  s.extra_rdoc_files = ["README.textile", "LICENSE", "TODO.textile"]
  s.files = ["LICENSE", "README.textile", "Rakefile", "TODO.textile", "lib/warden", "lib/warden/authentication", "lib/warden/authentication/hooks.rb", "lib/warden/authentication/strategies.rb", "lib/warden/authentication/strategy_base.rb", "lib/warden/errors.rb", "lib/warden/manager.rb", "lib/warden/mixins", "lib/warden/mixins/common.rb", "lib/warden/proxy.rb", "lib/warden.rb", "spec/helpers", "spec/helpers/request_helper.rb", "spec/spec_helper.rb", "spec/warden", "spec/warden/authenticated_data_store_spec.rb", "spec/warden/errors_spec.rb", "spec/warden/hooks_spec.rb", "spec/warden/manager_spec.rb", "spec/warden/proxy_spec.rb", "spec/warden/strategies", "spec/warden/strategies/failz.rb", "spec/warden/strategies/invalid.rb", "spec/warden/strategies/pass.rb", "spec/warden/strategies/pass_without_user.rb", "spec/warden/strategies/password.rb", "spec/warden/strategies_spec.rb", "spec/warden/strategy_base_spec.rb", "spec/warden_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/hassox/warden}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.0}
  s.summary = %q{Rack middleware that provides authentication for rack applications}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
