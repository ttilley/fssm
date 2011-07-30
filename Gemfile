source "http://rubygems.org"

gemspec

gem 'rake'

require 'rbconfig'
case Config::CONFIG['target_os']
  when /darwin/
    gem 'rb-fsevent', '>= 0.4.0', :require => false
  when /linux/
    gem 'ffi' # just to see if this helps rbx
    gem 'rb-inotify', '>= 0.8.5', :require => false
end

