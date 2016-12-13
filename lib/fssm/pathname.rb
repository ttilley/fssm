require 'fileutils'
require 'find'
require 'pathname'

module FSSM
  class Pathname < ::Pathname
    VIRTUAL_REGEX = /^file:([^!]*)!/

    class << self
      def for(path)
        path.is_a?(::FSSM::Pathname) ? path : new(path)
      end

      alias :[] :glob
    end

    def is_virtual?
      !!(VIRTUAL_REGEX =~ to_s)
    end

    def segments
      path  = to_s
      array = []
      while !Pathname.new(path).root? && !path.empty?
        array.unshift File.basename(path)
        path        = File.dirname(path)
      end
      array.unshift path unless path.empty?
      array
    end

    def glob(pattern, flags = 0, &block)
      patterns = [pattern].flatten
      patterns.map! { |p| self.class.glob(to_s + p, flags, &block) }
      patterns.flatten
    end
  end
end
