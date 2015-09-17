Gem::Specification.new do |spec|
  spec.name          = 'replace'
  spec.version       = '1.0.2'
  spec.date          = '2014-12-13'
  spec.platform      = Gem::Platform::RUBY
  spec.authors       = ['Henry He']
  spec.email         = ['henryhyn@163.com']

  spec.summary       = %q{replace file using Regexp}
  spec.description   = %q{replace file using Regexp.}
  spec.homepage      = 'https://github.com/henryhyn/replace'
  spec.license       = 'MIT'

  spec.files         = Dir['bin/*', 'lib/*']
  spec.bindir        = 'bin'
  spec.executables   = ['rep']
  spec.require_paths = ['lib']

  spec.required_rubygems_version = '>= 1.3.6'
  spec.rubyforge_project         = 'replace'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec'

  spec.add_runtime_dependency 'pandoc-ruby', '~> 1.0.0'
  spec.add_runtime_dependency 'ropencc', '~> 0.0.6'
end
