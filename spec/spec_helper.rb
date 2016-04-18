# encoding: utf-8
require "logstash/devutils/rspec/spec_helper"
require "logstash/outputs/zeromq"
require_relative "support/client"

module ZeroMQHelpers

  def setup_clients(number_of_clients, port)
    number_of_clients.times.inject([]) do |clients|
      clients << ZeroMQClient.new(localhost, port)
    end
  end

  def output(config, size, &block)
    plugin = LogStash::Plugin.lookup("output", "zeromq").new(config)
    plugin.register
    events = []
    size.times do |n|
      events << LogStash::Event.new({"message" => "data #{n}"})
    end
    pipeline_thread = Thread.new { plugin.multi_receive(events) }
    sleep 0.3
    result = block.call
    plugin.close
    pipeline_thread.join
    result
  end # def input

end

RSpec.configure do |config|
  config.include ZeroMQHelpers
  # config.filter_run_excluding({ :zeromq => true, :integration => true })
  config.order = :random
end
