require "spec"
require "../src/icmp"

HOST = "127.0.0.1"

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

    it "has the respnose status" do
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

