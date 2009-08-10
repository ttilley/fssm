module FileSystemStateMonitor::Watcher
  class FSEvents < Base
    def initialize(directory, options={})
      super
      @fsevents = nil
    end
    
    def start
      callback = self.method(:fsevents_callback)
      @fsevents = Rucola::FSEvents.start_watching(@directory, &callback)
    end
    
    def stop
      @fsevents.stop
    end
    
    private
    
    def fsevents_callback(events)
      events.each {|event| refresh(event.path)}
    end
  end
end
