
require 'ripl'
require 'ripl/multi_line'

module Rmap
  module Commands
    
    def self.console
      db = Rmap::Database.new
      
      current = Dir::getwd
      while current != '/'
        if ::File.file? "#{current}/conf.rmap.rb"
          db.run("#{current}/conf.rmap.rb")
          break
        end
        current = ::File.expand_path('../',  current)
      end

      Ripl.start :binding => db.bindings
    end
    
  end
end
