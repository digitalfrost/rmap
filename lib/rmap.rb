

module Rmap
  CONF_ROOT = nil
  current = Dir::getwd
  while current != '/'
    if ::File.file? "#{current}/rmap.conf.rb"
      CONF_ROOT = current
      break
    end
    current = ::File.expand_path('../', current)
  end
end

require 'rmap/version'
require 'rmap/database'
require 'rmap/table'
require 'rmap/row'
require 'rmap/migration'
require 'rmap/commands'

