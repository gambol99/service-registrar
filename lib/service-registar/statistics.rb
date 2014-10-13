#
#   Author: Rohith
#   Date: 2014-10-13 21:29:37 +0100 (Mon, 13 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  module Statistics
    private
    def statistics
      @statistics ||= set_default_statistics
    end

    def set_default_statistics
      {
        :started   => Time.now.to_i,
        :processed => 0,
      }
    end
  end
end
