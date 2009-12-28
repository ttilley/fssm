require 'yaml'
class FSSM::State
  def initialize(path)
    @path = path
    @cache = FSSM::Tree::Cache.new
    @created = []
    @modified = []
    @deleted = []
  end
  
  def refresh(base=nil, skip_callbacks=false)
    previous, current = recache(base || @path.to_pathname)
    refresh_keys(previous, current)

    if @path.collect
      @path.sleep(all_events) unless skip_callbacks
    else
      unless skip_callbacks    
        created(previous, current)
        modified(previous, current)
        deleted(previous, current)
      end
    end
  end

  private

  def refresh_keys(previous, current)
    @created = current.keys - previous.keys
    @modified.clear
    (current.keys & previous.keys).each do |file|
      @modified.push(file) if (current[file] <=> previous[file]) != 0
    end
    @deleted = previous.keys - current.keys
  end

  def all_events
    {
      :created => @created,
      :modified => @modified,
      :deleted => @deleted
    }
  end

  def created(previous, current)
    @created.each {|created| @path.create(created)}
  end

  def modified(previous, current)
    @modified.each { |modified| @path.update(modified) }
  end

  def deleted(previous, current)
    @deleted.each {|deleted| @path.delete(deleted)}
  end

  def recache(base)
    base = FSSM::Pathname.for(base)
    previous = @cache.files
    snapshot(base)
    current = @cache.files
    [previous, current]
  end

  def snapshot(base)
    base = FSSM::Pathname.for(base)
    @cache.unset(base)
    @path.glob.each {|glob| add_glob(base, glob)}
  end

  def add_glob(base, glob)
    FSSM::Pathname.glob(base.join(glob).to_s).each do |fn|
      @cache.set(fn)
    end
  end

end
