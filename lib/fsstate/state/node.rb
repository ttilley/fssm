module FileSystemStateMonitor::State
  class Node
    include Common
    
    attr_reader :subnodes, :state

    NodeState = Struct.new(:mtime, :size, :ftype) do
      def <=>(other)
        return unless other.is_a?(NodeState)
        self.mtime <=> other.mtime
      end
    end
    
    NodeState.members.each do |member|
      class_eval <<-EOT, __FILE__, __LINE__ + 1
        def #{member}
          @has_state ? @state.#{member} : nil
        end
        
        def #{member}=(val)
          @state ||= NodeState.new
          @has_state ||= true
          
          @state.#{member} = val
        end
      EOT
    end

    def initialize(attributes = false)
      @subnodes = {}
      @state = nil
      @has_state = false
      self.state = attributes if attributes
    end
    
    def state=(attributes={})
      NodeState.members.each do |member|
        self.send("#{member}=", attributes[member.to_sym])
      end
    end
    alias :set_state :state=
    
    def empty?
      !@has_state
    end

    def file?
      @has_state ? @state.ftype == 'file' : nil
    end

    def directory?
      @has_state ? @state.ftype == 'directory' : nil
    end
  end
end
