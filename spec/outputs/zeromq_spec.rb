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
end
