begin
  require 'debugger'
rescue LoadError => e
  require 'ruby-debug'
end

$: << File.expand_path('../../../lib', __FILE__)

require 'mime/message'
