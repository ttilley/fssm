module FileSystemStateMonitor::Watcher
  class Polling < Base
    def initialize(directory, options={})
      super
      @interval = options[:interval] || 1
      @thread = nil
    end
     
    def running?
      !@thread.nil?
    end
     
    def start
      return if running?
       
      @stop = false
      @thread = Thread.new(self) {|t| t.__send__ :run_loop}
      self
    end
     
    def stop
      return unless running?
       
      @stop = true
      @thread.wakeup if @thread.status == 'sleep'
      @thread.join
      self
    ensure
      @thread = nil
    end
     
    def join(limit = nil)
      return unless running?
      @thread.join limit
    end
           
    private
     
    def run_loop
      until @stop
        start = Time.now.to_f
         
        refresh
         
        nap_time = @interval - (Time.now.to_f - start)
        sleep nap_time if nap_time > 0
      end
    end
  end
end
