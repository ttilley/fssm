require 'fileutils'
require 'find'
require 'pathname'

module FSSM
  class Pathname < ::Pathname
    ROOT = '/'.freeze
    VIRTUAL_REGEX = /^file:([^!]*)!/

    class << self
      def for(path)
        path.is_a?(Pathname) ? path : new(path)
      end

      alias :[] :glob
    end
    
    def is_virtual?
      !!(VIRTUAL_REGEX =~ to_s)
    end

    def segments
      path = to_s
      array = path.split(File::SEPARATOR)
      array.delete('')
      array.insert(0, ROOT) if path[0,1] == ROOT
      array
    end

    def glob(pattern, flags = 0, &block)
      patterns = [pattern].flatten
      patterns.map! {|p| self.class.glob(to_s + p, flags, &block) }
      patterns.flatten
    end
  end
end
