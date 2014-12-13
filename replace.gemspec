Gem::Specification.new do |s|
  s.name        = %q{rep}
  s.version     = "2.0.0"
  s.date        = %q{2014-09-29}
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Henry He"]
  s.email       = ["henryhyn@163.com"]
  s.homepage    = "https://github.com/oboooks/rep"
  s.summary     = %q{rep is a ebook maker.}
  s.description = "the ebook generate tools from markdown plain text"

  s.required_rubygems_version = ">= 1.3.6"

  # lol - required for validation
  s.rubyforge_project         = "rep"

  # If you have other dependencies, add them here
  # s.add_dependency "another", "~> 1.2"

  # If you need to check in files that aren't .rb files, add them here
  s.files = Dir["bin/*","lib/*","template/.rep.yml","template/**/*"]
  s.require_paths = ["lib"]

  # If you need an executable, add it here
  s.executables = ["rep"]

  # If you have C extensions, uncomment this line
  # s.extensions = "ext/extconf.rb"
end