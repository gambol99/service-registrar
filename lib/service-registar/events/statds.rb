#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-14 11:24:23 +0100 (Tue, 14 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'ruby-statsd'

module ServiceRegistar
  module Events
    class Statsd
      attr_reader :config
      def initialize config
        @config = config
      end

      def increment key, value = 1

      end

      def gauge key, value

      end
    end
  end
end
