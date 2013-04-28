require File.expand_path('../lib/http_testing/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'http-testing'
  s.version     = HttpTesting::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Evgeny Myasishchev']
  s.email       = ['evgeny.myasishchev@gmail.com']
  s.homepage    = 'http://github.com/evgeny-myasishchev/http-testing'
  s.summary     = %q{Library for testing HTTP requests in Ruby.}
  s.description = %q{HttpTesting allows testing HTTP requests.}

  s.rubyforge_project     = 'http-testing'
  s.required_ruby_version = '>= 1.9.3'

  s.add_development_dependency 'rspec', '>= 2.0.0'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ['lib']
end
