require 'fileutils'
require 'find'
require 'pathname'

module FSSM
  class Pathname < ::Pathname
    ROOT = '/'.freeze

    class << self
      def new(path)
        path.is_a?(Pathname) ? path : super
      end

      alias :[] :glob
    end

    def to_a
      a = []
      a << '/' if absolute?
      each_filename(&a.method(:<<))
      a
    end

    def glob(pattern, flags = 0, &block)
      patterns = [pattern].flatten
      patterns.map! {|p| self.class.glob(to_s + p, flags, &block) }
      patterns.flatten
    end
  end
end
