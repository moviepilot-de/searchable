# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'searchable'
  spec.version       = '0.1.0'
  spec.authors       = ['Tim Bleck']
  spec.email         = ['tim@moviepilot.com']
  spec.summary       = %q{Elasticsearch integration for rails.}
  spec.description   = %q{Elasticsearch integration for rails.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.5'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.12.0'
  spec.add_development_dependency 'sqlite3'

  spec.add_runtime_dependency 'rails'
  spec.add_runtime_dependency 'hashr', '~> 0.0.22'
  spec.add_runtime_dependency 'elasticsearch', '~> 2.0.0'
  spec.add_runtime_dependency 'ruby-progressbar', '~> 1.2.0'
end
