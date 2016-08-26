# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# Write events to a 0MQ PUB socket.
#
# You need to have the 0mq 2.1.x library installed to be able to use
# this output plugin.
#
# The default settings will create a publisher connecting to a subscriber
# bound to tcp://127.0.0.1:2120
#
class LogStash::Outputs::ZeroMQ < LogStash::Outputs::Base
  # This will be a performance bottleneck. Someone needs to upgrade this to
  # concurrency :shared and make sure there is no breakage
  concurrency :single 

  config_name "zeromq"

  default :codec, "json"

  # 0mq socket address to connect or bind.
  # Please note that `inproc://` will not work with logstashi.
  # For each we use a context per thread.
  # By default, inputs bind/listen and outputs connect.
  config :address, :validate => :array, :default => ["tcp://127.0.0.1:2120"]

  # The default logstash topologies work as follows:
  #
  # * pushpull - inputs are pull, outputs are push
  # * pubsub - inputs are subscribers, outputs are publishers
  # * pair - inputs are clients, outputs are servers
  #
  # If the predefined topology flows don't work for you,
  # you can change the 'mode' setting
  config :topology, :validate => ["pushpull", "pubsub", "pair"], :required => true

  # This is used for the 'pubsub' topology only.
  # On inputs, this allows you to filter messages by topic.
  # On outputs, this allows you to tag a message for routing.
  # NOTE: ZeroMQ does subscriber-side filtering
  # NOTE: Topic is evaluated with `event.sprintf` so macros are valid here.
  config :topic, :validate => :string, :default => ""

  # Server mode binds/listens. Client mode connects.
  config :mode, :validate => ["server", "client"], :default => "client"

  # This exposes zmq_setsockopt for advanced tuning.
  # See http://api.zeromq.org/2-1:zmq-setsockopt for details.
  #
  # This is where you would set values like:
  #
  # * ZMQ::HWM - high water mark
  # * ZMQ::IDENTITY - named queues
  # * ZMQ::SWAP_SIZE - space for disk overflow
  #
  # Example:
  # [source,ruby]
  #     sockopt => {
  #        "ZMQ::HWM" => 50
  #        "ZMQ::IDENTITY"  => "my_named_queue"
  #     }
  config :sockopt, :validate => :hash

  public
  def register
    load_zmq

    connect
  end # def register

  public
  def close
    begin
      error_check(@zsocket.close, "while closing the socket")
    rescue RuntimeError => e
      @logger.error("Failed to properly teardown ZeroMQ")
    end
  end # def close

  def multi_receive_encoded(events_and_encoded)
    events_and_encoded.each {|event, encoded| self.publish(event,encoded)}
  end

  private
  def server?
    @mode == "server"
  end # def server?

  def publish(event, payload)
    if @topology == "pubsub"
      topic = event.sprintf(@topic)
      error_check(@zsocket.send_string(topic, ZMQ::SNDMORE), "in topic send_string")
    end
    @logger.debug? && @logger.debug("0mq: sending", :event => payload)
    error_check(@zsocket.send_string(payload), "in send_string")
  rescue => e
    warn e.inspect
    @logger.warn("0mq output exception", :address => @address, :exception => e)
  end

  def load_zmq
    require "ffi-rzmq"
    require "logstash/plugin_mixins/zeromq"
    self.class.send(:include, LogStash::PluginMixins::ZeroMQ)
  end

  def connect
    # Translate topology shorthand to socket types
    case @topology
    when "pair"
      zmq_const = ZMQ::PAIR
    when "pushpull"
      zmq_const = ZMQ::PUSH
    when "pubsub"
      zmq_const = ZMQ::PUB
    end # case socket_type

    @zsocket = context.socket(zmq_const)

    error_check(@zsocket.setsockopt(ZMQ::LINGER, 1),
                "while setting ZMQ::LINGER == 1)")

    if @sockopt
      setopts(@zsocket, @sockopt)
    end

    @address.each do |addr|
      setup(@zsocket, addr)
    end
  end
end # class LogStash::Outputs::ZeroMQ
