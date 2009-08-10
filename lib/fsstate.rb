require 'pathname'
require 'set'
require 'thread'

module FileSystemStateMonitor
  Error = Class.new(StandardError)
  EmptyKey = Class.new(Error)
  FileNotFound = Class.new(Error)
end

require 'fsstate/state'
require 'fsstate/watcher'
require 'fsstate/manager'
