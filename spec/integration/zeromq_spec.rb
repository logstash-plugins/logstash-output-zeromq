# encoding: utf-8
require_relative "../spec_helper"
require "logstash/plugin"
require "logstash/event"

describe LogStash::Outputs::ZeroMQ, :integration => true do

  describe "send events" do

    let(:nevents)  { 10 }
    let(:port)     { rand(1000)+1025 }

    let(:conf) do
      {  "address" => ["tcp://127.0.0.1:#{port}"],
         "topology" => "pushpull" }
    end

    let(:events) do
      output(conf, nevents) do
        res = []
        client = ZeroMQClient.new("127.0.0.1", port)
        nevents.times do
          res << client.recv
        end
        client.close
        res
      end
    end

    it "should receive the events" do
      expect(events.count).to be(nevents)
    end
  end
end
