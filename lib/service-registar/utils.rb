#
#   Author: Rohith (gambol99@gmail.com)
#   Date: 2014-10-14 17:31:09 +0100 (Tue, 14 Oct 2014)
#
#  vim:ts=2:sw=2:et
#
module ServiceRegistar
  module Utils
    def valid_file? filename
      return false "the configuration: #{filename} does not exists" unless File.exists? filename
      raise ArgumentError, "the configuration: #{filename} is not a file"   unless File.file? filename
      raise ArgumentError, "the configuration: #{filename} is not readable" unless File.readable? filename
    end

    def postive_integer? value
      ( !value.is_a? Integer or value <= 0 ) ? false : true
    end

    def required_settings list, supplied
      list.each do |x|
        raise ArgumentError, "you have not specified the #{x} options" unless supplied.has_key? x
      end
    end
  end
end
