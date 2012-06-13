
require 'ripl'
require 'ripl/multi_line'
require 'gengin'

module Rmap
  module Commands
    
    def self.console
      db = Rmap::Database.new
      
      if Rmap.const_defined? :CONF_ROOT
        db.run("#{Rmap::CONF_ROOT}/conf.rmap.rb")
      end

      Ripl.start :binding => db.bindings
    end
    
    module Generate
      
      def self.conf(database, options={})
        Gengin.new do
          source_root File.expand_path("../generator_templates/", __FILE__)
          @database = database
          copy "conf.rmap.rb", :erb => true
        end
      end
      
    end
    
  end
end
