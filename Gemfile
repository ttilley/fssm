source "http://rubygems.org"

gemspec

gem 'rake'

require 'rbconfig'
case Config::CONFIG['target_os']
  when /darwin/ then gem 'rb-fsevent', '>= 0.4.0', :require => false
  when /linux/ then gem 'rb-inotify', '>= 0.8.5', :require => false
end

