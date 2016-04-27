# encoding: utf-8
require_relative "../spec_helper"
require "logstash/plugin"
require "logstash/event"

describe LogStash::Outputs::ZeroMQ, :zeromq => true do

  context "when register and close" do

    let(:plugin) { LogStash::Plugin.lookup("output", "zeromq").new({ "topology" => "pushpull" }) }

    it "should register and close without errors" do
      expect { plugin.register }.to_not raise_error
      expect { plugin.do_close }.to_not raise_error
    end

  end

  context "pubsub" do
    let(:plugin) { LogStash::Plugin.lookup("output", "zeromq").new({"topology" => "pubsub", "topic" => "%{topic}"})}

    it "should use topic field as topic" do
      mock_socket = instance_double("ZMQ::Socket")
      expect(mock_socket).to receive(:send_string).with("test-topic", ZMQ::SNDMORE).and_return(0).ordered
      expect(mock_socket).to receive(:send_string).with("payload").and_return(0).ordered
      plugin.instance_variable_set(:@zsocket, mock_socket)
      plugin.send(:publish, LogStash::Event.new("topic" => "test-topic", "message" => "text"), "payload")
    end
  end
end
