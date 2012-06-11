
require 'ripl'
require 'ripl/multi_line'
require 'gengin'

module Rmap
  module Commands
    
    def self.console
      db = Rmap::Database.new
      
      if !Rmap::CONF_ROOT.nil?
        db.run("#{Rmap::CONF_ROOT}/conf.rmap.rb")
      end

      Ripl.start :binding => db.bindings
    end
    
    def Generate
      
      def self.conf(database, options={})
        Gengin.new do
          source_root File.expand_path("../generator_templates/", __FILE__)
          erb_var :database, database
          copy "conf.rmap.rb", :erb => true
        end
      end
      
    end
    
  end
end
