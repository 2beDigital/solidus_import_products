# frozen_string_literal: true

$:.push File.expand_path('lib', __dir__)
require 'solidus_import_products/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'solidus_import_products'
  s.version     = SolidusImportProducts::VERSION
  s.summary     = "solidus_import_products ... imports products. From a CSV file via Solidus's Admin interface"
  s.license     = 'BSD-3-Clause'

  s.author            = 'Guillermo Toro-Bayona'
  s.homepage          = 'https://github.com/memotoro/solidus_import_products'

  s.author            = 'NoelDiazMesa, ngelX'
  s.email             = 'noel@2bedigital.com, ngelx@protonmail.com'
  s.homepage          = 'https://github.com/2bedigital/solidus_import_products'


  if s.respond_to?(:metadata)
    s.metadata["homepage_uri"] = s.homepage if s.homepage
    s.metadata["source_code_uri"] = s.homepage if s.homepage
  end

  s.required_ruby_version = '~> 2.4'

  s.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  s.test_files = Dir['spec/**/*']
  s.bindir = "exe"
  s.executables = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'deface', '~> 1.0'
  s.add_dependency 'solidus_core', ['>= 2.0.0', '< 3']
  s.add_dependency 'solidus_support', '~> 0.4.0'
  s.add_dependency 'rubyzip', '~> 1.2'

  s.add_development_dependency 'shoulda-matchers', '~> 3.1'
  s.add_development_dependency 'vcr', '~> 4.0'
  s.add_development_dependency 'webmock', '~> 3.4'
  s.add_development_dependency 'solidus_dev_support'
end
