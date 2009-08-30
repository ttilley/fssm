class FSSM::Monitor
  def initialize(options={})
    @options = options
    @backend = FSSM::Backends::Default.new
  end
  
  def path(*args, &block)
    path = FSSM::Path.new(*args)
    path.instance_eval(&block) if block_given?
    @backend.add_path(path)
    path
  end
  
  def run
    @backend.run
  end
end
