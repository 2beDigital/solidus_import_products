Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_import_products'
  s.version     = '1.1.0'
  s.summary     = "solidus_import_products ... imports products. From a CSV file via Solidus's Admin interface"
  # s.description = 'Add (optional) gem description here'
  s.required_ruby_version = '>= 2.2.2'

  s.author            = 'ngelX'
  s.email             = 'ngelx@protonmail.com'
  s.homepage          = 'https://github.com/ngelx/solidus_import_products'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'deface'
  s.add_dependency 'solidus_auth_devise'
  s.add_dependency 'solidus_core', '>= 2.0'
  s.add_dependency 'solidus_support'

  s.add_development_dependency 'capybara', '~> 2.17'
  s.add_development_dependency 'factory_bot_rails', '~> 4.8'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'launchy', '~> 2.0.5'
  s.add_development_dependency 'rspec-rails', '~> 3.7.2'
  s.add_development_dependency 'shoulda-matchers', '~> 3.1'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'vcr'
  s.add_development_dependency 'webmock'
end
