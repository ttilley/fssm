module FileSystemStateMonitor::Watcher
  class Base
    def initialize(directory, options={})
      @directory = directory
      @glob = options[:glob] || ['**/*']
      @cache = options[:cache] || State::Cache.new
      
      @events = []
      @observers = {}
    end
    
    def add_observer(observer = nil, func = :update, &block)
      unless block.nil?
        observer = block.to_proc
        func = :call
      end

      unless observer.respond_to? func
        raise NoMethodError, "observer does not respond to `#{func.to_s}'"
      end

      @observers[observer] = func
      observer
    end
    
    def delete_observer(observer)
      @observers.delete(observer)
    end
    
    def clear_observers
      @observers.clear
    end

    def refresh(directory=nil)
      directory ||= @directory
      
      ofiles = @cache.files(directory)
      @cache.set(directory, @glob)
      nfiles = @cache.files(directory)
      
      okeys = ofiles.keys
      nkeys = nfiles.keys
      
      (nkeys - okeys).each {|add| @events << Event.new(:created, add)}
      (okeys - nkeys).each {|rem| @events << Event.new(:deleted, rem)}
      
      (nkeys & okeys).each do |key|
        if (nfiles[key] <=> ofiles[key]) != 0
          @events << Event.new(:modified, key)
        end
      end
      
      notify_observers
      self
    end
    
    private
    
    def notify_observers
      unless @events.empty?
        @observers.each do |observer, func|
          observer.send(func, *@events)
        end
        @events.clear
      end
    end
    
  end
end
