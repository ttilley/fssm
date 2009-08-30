module FSSM
  FileNotFoundError = Class.new(StandardError)
  CallbackError = Class.new(StandardError)
  
  class << self
    def monitor(*args, &block)
      monitor = FSSM::Monitor.new
      context = args.empty? ? monitor : monitor.path(*args)
      context.instance_eval(&block) if block_given?
      monitor.run
    end
  end
end

$:.unshift(File.dirname(__FILE__))
require 'pathname'
require 'fssm/ext'
require 'fssm/support'
require 'fssm/path'
require 'fssm/state'
require 'fssm/monitor'

require "fssm/backends/#{FSSM::Support.backend.downcase}"
FSSM::Backends::Default = FSSM::Backends.const_get(FSSM::Support.backend)
$:.shift

