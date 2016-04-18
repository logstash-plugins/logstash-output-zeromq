# encoding: utf-8
require 'ffi-rzmq'

class ZeroMQClient

  attr_reader :addr, :port, :context, :requester

  def initialize(addr, port)
    @addr   = addr
    @port   = port
    @context = ZMQ::Context.new(1)
    @requester = context.socket(ZMQ::PULL)
    @requester.bind("tcp://#{addr}:#{port}")
  end

  def recv
    s = ''
    @requester.recv_string s
    s
  end

  def close
    @requester.close
    @context.terminate
  end
end
