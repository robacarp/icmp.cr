require "socket"

require "./icmp/**"

module ICMP
  IP_HEADER_SIZE_8 = 20
  PACKET_LENGTH_8 = 16
  PACKET_LENGTH_16 = 8

  class Ping
    getter address
    property sender_id = 1_u16

    def self.ping(host)
      instance = new(host)
      instance.ping
      instance.statistics
    end

    def initialize(@host : String)
      @requests = [] of EchoRequest
      @address = Socket::IPAddress.new @host, 0
      @socket = IPSocket.new Socket::Family::INET, Socket::Type::DGRAM, Socket::Protocol::ICMP
    end

    def ping(*, count = 1)
      ping(count: count) { |response| ; }
    end

    def ping(*, count = 1, &block)
      count.times do
        request = EchoRequest.new(@requests.size.to_u16, sender_id)
        @requests.push request
        request.sent_at Time.now
        send request

        if responded_request = receive_response
          yield responded_request
        end

        sleep 0.1
      end

      statistics
    end

    def finalize
      socket.close if socket
    end

    def statistics
      counts = @requests.group_by {|r| r.responded_to? }
      success = counts[true]? || [] of Nil
      fail = counts[false]? || [] of Nil

      total_response_time = @requests.map {|r| r.roundtrip_time }
                                     .reject {|r| r == -1 }
                                     .reduce(0.0) { |sum, time| sum += time }

      {
        count: @requests.size,
        success: success.size,
        fail: fail.size,
        average_response: total_response_time / @requests.size
      }
    end

    private def socket : IPSocket
      return @socket if @socket
      abort "No open socket"
    end

    private def send(request : EchoRequest)
      socket.send request.render, to: address
    end

    private def receive_response : EchoRequest | Nil
      buffer = Bytes.new(PACKET_LENGTH_8 + IP_HEADER_SIZE_8)
      count, address = socket.receive buffer
      timestamp = Time.now

      length = buffer.size
      icmp = buffer[IP_HEADER_SIZE_8, length-IP_HEADER_SIZE_8]

      response = EchoResponse.new(icmp, address)
      response.received_at timestamp

      request = @requests[response.sequence]?

      return unless request

      if request.responded_to?
        request.status = :double_response
      else
        if response.valid? && request == response
          request.responded_to = true
          request.response = response

          request.status = :valid_response
        else
          request.status = :invalid_response
        end
      end

      request
    end

  end
end

