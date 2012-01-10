lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'wildcloud/git/version'

Gem::Specification.new do |s|
  s.name        = 'wildcloud-git'
  s.version     = Wildcloud::Git::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Marek Jelen']
  s.email       = ['marek@jelen.biz']
  s.homepage    = 'http://github.com/wildcloud'
  s.summary     = 'Git repositories management'
  s.description = 'Manages git repositories, authentication information for OpenSSH and authorization.'
  s.license     = 'Apache2'

  s.required_rubygems_version = '>= 1.3.6'

  s.add_dependency 'amqp', '0.8.4'
  s.add_dependency 'json', '1.6.4'
  s.add_dependency 'wildcloud-logger', '0.0.2'
  s.add_dependency 'wildcloud-configuration', '0.0.1'

  s.files        = Dir.glob('{bin,lib}/**/*') + %w(LICENSE README.md CHANGELOG.md)
  s.executables = %w(wildcloud-git wildcloud-git-client)
  s.require_path = 'lib'
end