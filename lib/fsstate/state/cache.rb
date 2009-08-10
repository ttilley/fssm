module FileSystemStateMonitor::State
  class Cache
    include Common

    def initialize(glob=nil)
      @subnodes = {}
      @glob = glob || ['**/*']
    end

    def find(paths, &block)
      paths = expanded_unique_paths(paths)

      paths.each do |path|
        node = get(path)
        next unless node

        synchronize do            
          node.each(key_for_path(path)) do |key, node|
            next if node.empty?
            kpath = path_for_key(key)
            yield(kpath, node)
          end
        end
      end
    end

    def files(paths=nil, &block)
      ftype(paths, 'file', &block)
    end

    def directories(paths=nil, &block)
      ftype(paths, 'directory', &block)
    end

    def set(paths, glob=nil)
      paths = expanded_unique_paths(paths)

      paths.each do |path|
        raise FileNotFound, "#{path} doesn't exist" unless path.exist?
        unset(path)
      end

      glob ||= @glob

      file_paths = paths.inject(Set.new) do |found, path|
        glob.each do |glob|
          Pathname.glob(path.join(glob)).each do |gpath|
            next unless gpath.file?
            found << gpath
          end
        end

        found
      end

      file_paths.each do |path|
        super(path, state_for_path(path))
      end

      self
    end

    def get(path_or_key)
      param = path_or_key.is_a?(Array) ? path_or_key : expanded_path(path_or_key)
      super(param)
    end

    def unset(path_or_key)
      param = path_or_key.is_a?(Array) ? path_or_key : expanded_path(path_or_key)
      super(param)
    end

    private

    def ftype(paths=nil, ftype='file')
      paths ||= ['/']
      results = {}

      find(paths) do |path, node|
        next unless node.send("#{ftype}?")
        results[path] = node.state
      end

      results
    end

  end
end