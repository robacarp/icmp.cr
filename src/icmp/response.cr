module ICMP
  class EchoResponse < Packet
    TYPE = 0_u16

    getter type : UInt16
    getter code : UInt16
    getter sender_id : UInt16
    getter sequence : UInt16

    property timestamp

    def initialize(buffer : Bytes, response_address : Socket::Address)
      @packet = [] of UInt16

      buffer.each_slice(2) do |slice|
        @packet.push((slice[0].to_u16 << 8) | slice[1])
      end

      @type = packet[0] >> 8
      @code = packet[0] & 0xff
      @sender_id = packet[2]
      @sequence = packet[3]
    end

    def received_at(@timestamp : Time)
    end

    def valid?
      check_checksum
    end

    def ==(request : EchoRequest)
      request.sequence == sequence && request.sender_id == sender_id
    end
  end
end
