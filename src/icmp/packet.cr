module ICMP
  abstract class Packet
    property packet : Array(UInt16)

    def initialize
      @packet = [] of UInt16
    end

    # Header Checksum
    #     The 16 bit one's complement of the one's complement sum of all 16
    #     bit words in the header.  For computing the checksum, the checksum
    #     field should be zero.  This checksum may be replaced in the
    #     future.
    # RFC 792, Page 2
    #
    # Also credit http://netfor2.com/checksum.html (2017-11-07) for an understable
    # walkthrough on how the carry bits are handled
    def calculate_checksum : UInt16
      # Ones complement math:
      # - Add the numbers
      # - add all the carry bits to the sum
      # - Done in 32bits so that the carries don't fall off
      checksum = 0_u32

      packet.each do |byte|
        checksum += byte
      end

      # Add any carry bits back to the LSB
      checksum += checksum >> 16

      # take the ones complement of the ones complement sum
      checksum = checksum ^ 0xffff_ffff_u32

      # truncate the number and map back to 16 bits
      (checksum & 0xffff).to_u16
    end

    def check_checksum
      0 == calculate_checksum
    end

    def debug(pkt, bit_size = 16)
      pkt.each_with_index do |byte, index|
        print "#{index}: "
        puts fmt(byte, bit_size)

        puts if (index + 1) % 8 == 0
      end
    end

    def pad(n, bit_size = 16)
      s = n.to_s(2)
      s = "#{"0" * Math.max(0, bit_size - s.size)}#{s}"
    end

    def fmt(n, bit_size = 16)
      formatted = ""
      pad(n, bit_size).chars.reverse.each_with_index do |c, i|
        formatted += c
        formatted += " " if (i + 1) % 4 == 0
      end

      formatted = "#{formatted.reverse.strip} ("
      if 32 <= n <= 122
        formatted += "\"#{n.chr}\" "
      else
        formatted += "    "
      end

      formatted += "#{n.to_s(16)})"
    end
  end
end
