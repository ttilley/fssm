module FileSystemStateMonitor::Watcher
  Event = Struct.new(:type, :path)
end

require 'fsstate/watcher/base'
require 'fsstate/watcher/polling'
require 'fsstate/watcher/fsevents'
