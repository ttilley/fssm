module FSSM::Backends
  class RBFSEvent
    def initialize
      @fsevent = FSEvent.new
    end

    def add_handler(handler, preload=true)
      @fsevent.watch handler.path.to_s do |paths|
        paths.each do |path|
          handler.refresh(path)
        end
      end

      handler.refresh(nil, true) if preload
    end

    def run
      begin
        @fsevent.run
      rescue Interrupt
        @fsevent.stop
      end
    end

  end
end
