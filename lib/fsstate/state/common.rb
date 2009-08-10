module FileSystemStateMonitor::State::Common
  def synchronize(&block)
    Semaphore.synchronize(&block)
  end
  
  def set(path_or_key, state=false)
    key = key_for_path(path_or_key)
    set_one(key, state)
  end

  def get(path_or_key)
    key = key_for_path(path_or_key)
    key.empty? ? self : recurse_on_key(key, false)
  end

  def unset(path_or_key)
    key = key_for_path(path_or_key)
    segment = key.pop
    
    node = get(key)
    return unless node
    
    synchronize do
      node.subnodes.delete(segment.to_sym)
    end
  end

  def each(prefix=[], &block)
    @subnodes.each do |segment, node|
      key = prefix.dup.push(segment)

      catch(:prune) do
        yield(key, node)
        node.each(key, &block)
      end
    end
  end

  private

  def set_one(key, state=false)
    raise EmptyKey, "key is empty #{key.inspect}" if key.empty?

    node = recurse_on_key(key)
    
    if state          
      synchronize do
        node.set_state(state.to_hash)
      end
    end
  end

  def recurse_on_key(key, create=true)
    catch(:node) do
      subnodes = @subnodes
      node = nil

      while !key.empty?
        segment = key.shift.to_sym
        
        if subnodes.has_key?(segment)
          node = subnodes[segment]
        else
          throw(:node, nil) unless create              
          synchronize do
            node = (subnodes[segment] ||= Node.new)
          end
        end

        subnodes = node.subnodes
      end

      throw(:node, node)
    end
  end

  def path_for_key(key)
    path = Pathname.new('/')
    return path if key.empty?
    key = key.map {|s| s.to_s}
    key.each do |s|
      path = path.join(s)
    end
    path
  end

  def key_for_path(path)
    if path.is_a?(Array)
      key = path
    else
      key = []
      Pathname.new(path).cleanpath.each_filename {|fn| key << fn}
    end

    key.shift if key[0] && key[0].empty?
    key.shift if key[0] && key[0] == '.'

    key
  end

  def state_for_path(path)      
    {:ftype => path.ftype, :mtime => path.mtime, :size => path.size}
  end

  def expanded_unique_paths(paths)
    paths = Set.new(paths) unless paths.is_a?(Set)
    paths.map! do |path|
      expanded_path(path)
    end
    paths
  end

  def expanded_path(path)
    (path.is_a?(Pathname) ? path : Pathname.new(path)).expand_path
  end
end
