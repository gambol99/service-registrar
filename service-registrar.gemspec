#
#   Author: Rohith
#   Date: 2014-10-10 20:52:12 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','lib/service-registrar' )
require 'version'

Gem::Specification.new do |s|
  s.name        = "service-registrar"
  s.version     = GemMirror::VERSION
  s.platform    = Gem::Platform::RUBY
  s.date        = '2014-10-10'
  s.authors     = ["Rohith Jayawardene"]
  s.email       = 'gambol99@gmail.com'
  s.homepage    = 'https://github.com/gambol99/service-registrar'
  s.summary     = %q{Docker Service Registration}
  s.description = %q{Probes the docker container and pushed to the services to a backend}
  s.license     = 'GPL'
  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.add_dependency 'zookeeper'
  s.add_dependency 'etcd'
  s.add_dependency 'optionscrapper'
  s.add_dependency 'ruby-statsd'
  s.add_dependency 'docker'
  s.add_dependency 'docker-api'
end
