module FileSystemStateMonitor::State
  Semaphore = Mutex.new
end

require 'fsstate/state/common'
require 'fsstate/state/node'
require 'fsstate/state/cache'
