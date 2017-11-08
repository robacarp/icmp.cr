module ICMP
  class EchoRequest < Packet
    TYPE = 8_u16
    MESSAGE = "ohai ICMP"

    getter sequence
    getter sender_id
    property responded_to = false

    getter timestamp
    getter response : EchoResponse | Nil
    getter status : Symbol

    def initialize(@sequence : UInt16, @sender_id : UInt16)
      # Fill the packet with the message, skipping the first 4 16bit words
      @packet = Array(UInt16).new PACKET_LENGTH_16 do |i|
        if i > 4
          MESSAGE[ i % MESSAGE.size ].ord.to_u16
        else
          0_u16
        end
      end

      packet[0] = (TYPE.to_u16 << 8)
      packet[1] = 0_u16
      packet[2] = sender_id
      packet[3] = sequence

      packet[1] = calculate_checksum

      @status = :not_sent
    end

    def render
      eight_bit_packet = packet.map do |word|
        [(word >> 8), (word & 0xff)]
      end.flatten.map(&.to_u8)

      slice = Bytes.new(PACKET_LENGTH_8)

      eight_bit_packet.each_with_index do |chr, i|
        slice[i] = chr
      end

      slice
    end

    def ==(response : EchoResponse)
      response.sequence == sequence && response.sender_id == sender_id
    end

    def responded_to?
      responded_to
    end

    def roundtrip_time
      response_packet = response
      return -1 unless response_packet

      send_time = timestamp
      receive_time = response_packet.timestamp

      return -1 unless send_time
      return -1 unless receive_time

      (receive_time - send_time).milliseconds
    end

    def sent_at(@timestamp : Time)
      @status = :sent
    end

    def response=(@response : EchoResponse)
    end

    def status=(@status : Symbol)
    end
  end
end
