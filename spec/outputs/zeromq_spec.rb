# encoding: utf-8
require "logstash/outputs/zeromq"
require "logstash/devutils/rspec/spec_helper"

describe LogStash::Outputs::ZeroMQ do
  let(:tracer) { double("logger") }

  context "when in server mode" do
    let(:output) { described_class.new("mode" => "server", "topology" => "pushpull" ) }

    it "a 'bound' info line is logged" do
      allow(tracer).to receive(:debug)
      output.logger = tracer
      expect(tracer).to receive(:info).with("0mq: bound", {:address=>"tcp://127.0.0.1:2120"})
      output.register
      output.do_close
    end
  end

  context "when in client mode" do
    let(:output) { described_class.new("mode" => "client", "topology" => "pushpull" ) }

    it "a 'connected' info line is logged" do
      allow(tracer).to receive(:debug)
      output.logger = tracer
      expect(tracer).to receive(:info).with("0mq: connected", {:address=>"tcp://127.0.0.1:2120"})
      output.register
      output.do_close
    end
  end
end