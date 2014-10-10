# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/driver/vsphere_version.rb'

Gem::Specification.new do |gem|
  gem.name          = "kitchen-vsphere"
  gem.version       = Kitchen::Driver::VSPHERE_VERSION
  gem.license       = 'Apache 2.0'
  gem.authors       = ["Matt Wrock"]
  gem.email         = ["matt@mattwrock.com"]
  gem.description   = "A Test Kitchen Driver for VMWare vShere"
  gem.summary       = gem.description
  gem.homepage      = "https://github.com/mwrock/kitchen-vsphere"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = []
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'test-kitchen', '~> 1.0'
  gem.add_dependency 'rbvmomi'
  gem.add_dependency 'fog'

  gem.add_development_dependency 'cane'
  gem.add_development_dependency 'tailor'
  gem.add_development_dependency 'countloc'
end
