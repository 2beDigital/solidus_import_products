Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_import_products'
  s.version     = '3.0.0'
  s.summary     = "solidus_import_products ... imports products. From a CSV file via Solidus's Admin interface"
  s.required_ruby_version = '>= 2.2.2'

  s.author            = 'NoelDiazMesa, ngelX'
  s.email             = 'noel@2bedigital.com, ngelx@protonmail.com'
  s.homepage          = 'https://github.com/2bedigital/solidus_import_products'

  s.author            = 'Guillermo Toro-Bayona'
  s.homepage          = 'https://github.com/memotoro/solidus_import_products'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'

  s.add_dependency 'deface', '~> 1.0'
  s.add_dependency 'solidus_auth_devise', '~> 2.1'
  s.add_dependency 'solidus_core', '~> 2.0'
  s.add_dependency 'solidus_support', '~> 0.2'
  s.add_dependency 'rubyzip', '~> 1.2'

  s.add_development_dependency 'capybara', '~> 2.17'
  s.add_development_dependency 'factory_bot_rails', '~> 4.8'
  s.add_development_dependency 'ffaker', '~> 2.9'
  s.add_development_dependency 'rspec-rails', '~> 3.7'
  s.add_development_dependency 'shoulda-matchers', '~> 3.1'
  s.add_development_dependency 'simplecov', '~> 0'
  s.add_development_dependency 'sqlite3', '~> 1.3'
  s.add_development_dependency 'vcr', '~> 4.0'
  s.add_development_dependency 'webmock', '~> 3.4'
end
