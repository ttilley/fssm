source "http://rubygems.org"

gemspec

case Gem::Platform.local.os
  when /darwin/ then gem 'rb-fsevent', '>= 0.4.0'
  when /linux/ then gem 'rb-inotify', '>= 0.8.5'
end

