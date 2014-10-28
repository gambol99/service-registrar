#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-14 17:31:09 +0100 (Tue, 14 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'logger'

module ServiceRegistrar
  module Utils
    LogLevels = {
      'info'  => ::Logger::INFO,
      'debug' => ::Logger::DEBUG,
    }

    def split_array list, symbol = '='
      list.inject({}) do |map,element|
        elements = element.split symbol
        map[elements.first] = elements.last if elements.size > 0
        map
      end
    end

    def env key, default
      return default unless ENV[key]
      # step: check if the variable is empty
      if ENV[key].empty?
        error "env: the environment variable: #{key} is there, but empty - return #{default}"
        default
      else
        debug "env: environment: #{key}, value: #{ENV[key]}"
        ENV[key]
      end
    end

    def wake milli, &block
      loop do
        sleep ( milli / 1000 )
        yield
      end
    end

    def uri_port uri
      URI(uri).port
    end

    def uri_hostname uri
      URI(uri).hostname
    end

    def loglevel level
      LogLevels[level] || ::Logger::DEBUG
    end

    def get_host_ipaddress
      @host_ipaddress ||= %x(hostname --ip-address).chomp
    end

    def required_settings list, supplied
      list.each { |x| raise ArgumentError, "you've not specified the #{x} option" unless supplied.has_key? x }
    end
  end
end
