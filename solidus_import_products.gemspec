Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_import_products'
  s.version     = '1.0.4'
  s.summary     = "solidus_import_products ... imports products. From a CSV file via Solidus's Admin interface"
  #s.description = 'Add (optional) gem description here'
  s.required_ruby_version = '>= 2.2.2'

  s.author            = '2BeDigital'
  s.email             = '2bedigital@2bedigital.com'
  s.homepage          = 'http://www.2BeDigital.com'

  s.files        = Dir['CHANGELOG', 'README.md', 'LICENSE', 'lib/**/*', 'app/**/*']
  s.require_path = 'lib'
  s.requirements << 'none'


  s.add_dependency 'solidus_core', '>= 2.0'
  s.add_dependency 'solidus_auth_devise'

  s.add_development_dependency 'capybara', '2.4.4'
  s.add_development_dependency 'factory_girl', '~> 4.4'
  s.add_development_dependency 'ffaker'
  s.add_development_dependency 'rspec-rails', '~> 3.1.0'
  s.add_development_dependency 'sqlite3'
	s.add_development_dependency 'launchy', '~> 2.0.5'
  s.add_development_dependency 'ruby-debug19'

end
