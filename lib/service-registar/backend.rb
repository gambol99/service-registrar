#
#   Author: Rohith
#   Date: 2014-10-13 20:45:39 +0100 (Mon, 13 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  class Backend
    include ServiceRegistar::Logging
    attr_reader :config
    def initialize config
      @config = config
    end

    def self.valid? configuration
      false
    end
  end
end
