Gem::Specification.new do |s|
  s.name        = 'replace'
  s.version     = '1.0.0'
  s.date        = '2014-12-13'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Henry He']
  s.email       = ['henryhyn@163.com']
  s.summary     = 'replace file using Regexp'
  s.description = 'replace file using Regexp.'

  s.required_rubygems_version = '>= 1.3.6'

  # lol - required for validation
  s.rubyforge_project         = 'replace'

  # If you have other dependencies, add them here
  s.add_dependency 'pandoc-ruby', '~> 0.7.5'
  s.add_dependency 'ropencc', '~> 0.0.6'

  # If you need to check in files that aren't .rb files, add them here
  s.files = Dir['bin/*', 'lib/*']
  s.require_paths = ['lib']

  # If you need an executable, add it here
  s.executables = ['rep']

  # If you have C extensions, uncomment this line
  # s.extensions = 'ext/extconf.rb'
end
