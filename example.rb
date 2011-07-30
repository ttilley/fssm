$:.unshift File.expand_path 'lib'

require 'fssm'

FSSM.monitor('.', '**/*') do
  update { |b, r| puts "Update in #{b} to #{r}" }
  delete { |b, r| puts "Delete in #{b} to #{r}" }
  create { |b, r| puts "Create in #{b} to #{r}" }
end

# please note that for anything beyond simple block callbacks like above, you
# will want to use the block parameter version of the API rather than the
# automagical eval-in-context version:
#
# FSSM.monitor('.', '**/*') do |mon|
#   mon.update { |b, r| puts "Update in #{b} to #{r}" }
#   mon.delete { |b, r| puts "Delete in #{b} to #{r}" }
#   mon.create { |b, r| puts "Create in #{b} to #{r}" }
# end

