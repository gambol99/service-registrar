#
#   Author: Rohith
#   Date: 2014-10-10 21:08:18 +0100 (Fri, 10 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
require 'logger'

module ServiceRegistar
  module Logging
    Logger.init settings[:loglevel] if settings[:verbose]

    %w(info warn error debug).each do |x|
      define_method x.to_sym do |message|
        Logger.send x.to_sym,message
      end
    end

    class Logger
      class << self
      attr_accessor :logger

      def init loglevel
        self.logger = ::Logger.new(STDOUT)
        self.logger.level = loglevel
      end

      def method_missing(m,*args,&block)
        logger.send m, *args, &block if logger.respond_to? m
      end
    end
  end
end
