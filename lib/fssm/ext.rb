class Pathname
  class << self
    def for(path)
      path.is_a?(Pathname) ? path : new(path)
    end
  end
  
  def segments
    prefix, names = split_names(@path)
    names.unshift(prefix) unless prefix.empty?
    names.shift if names[0] == '.'
    names
  end
  
  def names
    prefix, names = split_names(@path)
    names
  end
end
