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
      ping(host) {|r|}
    end

    def self.ping(host, &block)
      instance = new(host)
      instance.ping do |r|
        yield r
      end
      instance.statistics
    end

    def initialize(@host : String)
      unless Socket.ip? @host
        raise "ICMP Ping must be targeted at an IP Address"
      end

      @requests = [] of EchoRequest
      @address = Socket::IPAddress.new @host, 0

      socket_type = Socket::Type::RAW

      {% if flag?(:darwin) %}
        socket_type = Socket::Type::DGRAM
      {% end %}

      @socket = if @host.includes? ":"
        # doesnt work
        IPSocket.new Socket::Family::INET6, Socket::Type::DGRAM, Socket::Protocol.new(58)
      else
        IPSocket.new Socket::Family::INET, socket_type, Socket::Protocol::ICMP
      end
    end

    def ping(*, count = 1)
      ping(count: count) { |response| ; }
    end

    def ping(*, count = 1, timeout = 10, delay = 0.1, &block)
      count.times do
        request = EchoRequest.new(@requests.size.to_u16, sender_id)
        @requests.push request
        request.sent_at Time.now
        send request

        @socket.read_timeout = timeout
        begin
          if responded_request = receive_response
            yield responded_request
          end
        rescue IO::Timeout
          # act like nothing happened (which it didn't)
        end

        sleep delay
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
