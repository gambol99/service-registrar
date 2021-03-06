#
#   Author: Rohith
#   Date: 2014-10-10 20:52:34 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
$:.unshift File.join(File.dirname(__FILE__),'.','./service-registrar')
require 'registrar'

module ServiceRegistrar
  ROOT = File.expand_path(File.dirname(__FILE__))

  require "#{ROOT}/service-registrar/version"

  autoload :Version,  "#{ROOT}/service-registrar/version"
  autoload :Utils,    "#{ROOT}/service-registrar/misc/utils"
  autoload :Logging,  "#{ROOT}/service-registrar/misc/logging"
  autoload :Errors,   "#{ROOT}/service-registrar/misc/errors"

  def self.version
    ServiceRegistrar::VERSION
  end

  def self.new(options)
    ServiceRegistrar::Registrar.new options
  end
end
