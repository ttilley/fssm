require 'bundler/setup'
require 'fssm'

$LOAD_PATH.unshift(File.dirname(__FILE__))

RSpec.configure do |config|
  config.before :all do
    @watch_root = FSSM::Pathname.new(__FILE__).dirname.join('root').expand_path
  end
end

