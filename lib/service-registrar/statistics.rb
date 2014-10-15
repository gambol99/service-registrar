#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-15 12:44:54 +0100 (Wed, 15 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistrar
  module Statistics
    def statistics_runner
      info "statistics_runner: starting the statistics running thread"
      @statistics_dump ||= Thread.new do
        loop do
          info "statistics dump: #{statistics}"
          sleep_ms 10000
        end
        info "statistics_runner: thread ended"
      end
    end

    def increment key, by = 1
      statistics[key] ||= 0
      statistics[key] += 1
    end

    def gauge key, value
      statistics[key] = value
    end

    def measure_time key
      start_time = Time.now.to_i
      response = yield if block_given?
      statistics[key] = ( Time.now.to_i - start_time )
      response
    end

    private
    def statistics
      @statistics ||= {}
    end
  end
end
