require "spec"
require "../src/icmp"

HOST = "127.0.0.1"
BAD_HOST = "1.2.3.4" # should be a host that does not respond to ping

describe "icmp" do

  describe "class interface" do
    it "can be called with a block" do
      ICMP::Ping.ping(HOST) do |response|
      end
    end

    it "can be called without a block" do
      ICMP::Ping.ping(HOST)
    end
  end

  it "calls the block with each ping" do
    block_called = false
    ICMP::Ping.ping(HOST) do |response|
      block_called = true
    end

    block_called.should be_true
  end

  it "sends `count` pings" do
    ping_count = 3
    yield_count = 0

    ICMP::Ping.new(HOST).ping(count: ping_count) do |request|
      yield_count += 1
    end

    yield_count.should eq ping_count
  end

  it "honors short delay" do
    ping_count = 3
    delay = 0.1

    elapsed = Time.measure do
      ICMP::Ping.new(HOST).ping(count: ping_count, delay: delay) do |request|
      end
    end.to_f

    elapsed.should be_close(delay * ping_count, delay / 2.0)
  end

  it "honors long delay" do
    ping_count = 3
    delay = 3.0

    elapsed = Time.measure do
      ICMP::Ping.new(HOST).ping(count: ping_count, delay: delay) do |request|
      end
    end.to_f

    elapsed.should be_close(delay * ping_count, delay / 2.0)
  end

  it "times out waiting for unreachable host" do
    ping_count = 3
    yield_count = 0
    timeout = 1

    elapsed = Time.measure do
      ICMP::Ping.new(BAD_HOST).ping(count: ping_count, timeout: timeout) do |request|
        yield_count += 1 unless request.status == :invalid_response
      end
    end.to_f

    yield_count.should eq 0
    elapsed.should be_close(ping_count * timeout, timeout / 2.0)
  end

  describe "response object" do
    it "has the roundtrip time" do
      ICMP::Ping.ping(HOST) do |response|
        response.roundtrip_time.should_not be_nil
      end
    end

    it "has the sequence number" do
      ICMP::Ping.ping(HOST) do |response|
        response.sequence.should eq 0
      end
    end

    it "has the response status" do
      ICMP::Ping.ping(HOST) do |response|
        response.status.should be_a Symbol
      end
    end
  end

  describe "sequence number" do
    it "increases" do
      sequence_number = 0

      ICMP::Ping.new(HOST).ping(count: 11) do |response|
        response.sequence.should eq sequence_number
        sequence_number += 1
      end
    end
  end
end

