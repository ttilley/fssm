module FileSystemStateMonitor
  class << self
    def new(options={})
      Manager.new(options)
    end
  end
  
  class Manager
    def initialize(options={})
      @options = options
      
      @logger = @options[:logger]
      
      unless @logger
        require 'logger'
        @logger = ::Logger.new(STDERR)
        @logger.level = ::Logger::DEBUG
        @options[:logger] = @logger
      end
      
      @cache = State::Cache.new
      @options.merge!(:cache => @cache)
      
      @method = determine_method(@options.delete(:method))
      @options.merge!(:method => @method)
      
      @watchers = {}
      
      if @logger.debug?
        @logger.debug("FileSystemStateMonitor::Manager instantiated")
        @logger.debug("  method: #{@method}")
        @logger.debug("  options: #{@options.inspect}")
      end
      
    end
        
    def add_path(path, options={})
      path = expanded_path(path)
      symbol = path.to_s.to_sym
      @watchers[symbol] = new_watcher(path, options.merge(@options))
      
      if @logger.debug?
        logger_callback = self.method(:log_events)
        add_observer(path, &logger_callback)
      end
    end
    
    def add_observer(path, observer = nil, func = :update, &block)
      path = expanded_path(path)
      symbol = path.to_s.to_sym
      watcher = @watchers[symbol]
      
      watcher.add_observer(observer, func, &block)
    end
    
    def watch
      @logger.info("starting file system watchers...") if @logger.info?
      
      @watchers.each_value do |watcher|
        watcher.start
      end
      
      watch_until_interrupted
    end
    
    private
    
    def log_events(events=[])
      events.each {|event| @logger.debug("#{event.path} #{event.type}")}
    end
    
    def determine_method(method=nil)
      if method.nil? or method == :auto
        method = RUBY_PLATFORM =~ /darwin9/ ? :fsevents : :poll
      end
      
      if method == :fsevents
        unless defined?(Rucola) && defined?(Rucola::FSEvents)
          @logger.error("Rucola FSEvents library not loaded")
          @logger.error("Falling back to poller")
          method = :poll
        end
      end
      
      method
    end
    
    def new_watcher(path, options)
      case @method
      when :fsevents then Watcher::FSEvents.new(path, options)
      else
        Watcher::Poll.new(path, options)
      end
    end
    
    def watch_until_interrupted
      @logger.debug("watching paths until interrupted...") if @logger.debug?
      
      @logger.info("press ctrl-c to exit") if @logger.info?
      Signal.trap("INT") do
        @watchers.each {|watcher| watcher.stop}
        exit 0
      end
      
      case @method
      when :fsevents
        OSX.CFRunLoopRun
      else
        @watchers.each {|watcher| watcher.join}
      end
    end
    
    def expanded_path(path)
      (path.is_a?(Pathname) ? path : Pathname.new(path)).expand_path
    end
  end
  
end
