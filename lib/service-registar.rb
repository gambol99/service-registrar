#
#   Author: Rohith
#   Date: 2014-10-10 20:52:34 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./service-registar')
require 'docker'

module ServiceRegistar
  ROOT = File.expand_path( File.dirname( __FILE__ ) )

  equire "#{ROOT}/service-registar/version"

  autoload :Version,  "#{ROOT}/service-registar/version"
  autoload :Utils,    "#{ROOT}/service-registar/utils"
  autoload :Logging,  "#{ROOT}/service-registar/logging"

  def self.version
    ServiceRegistar::VERSION
  end

  def self.new options
    ServiceRegistar::Registar.new options
  end
end
