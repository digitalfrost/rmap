
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
      
      def self.migration(name, *columns, options)
        if !Rmap.const_defined? :CONF_ROOT
          raise "Could not find a conf.rmap.rb file in your path."
        end
        
        Gengin.new do
          source_root File.expand_path("../generator_templates/", __FILE__)
          destination_root "#{Rmap::CONF_ROOT}/migrations"
          @name = name
          @columns = columns
          
          if !::File.file?("#{Rmap::CONF_ROOT}/migrations/version.rmap.rb")
            copy "version.rmap.rb"
          end
          
          copy "migration.rmap.rb", "#{Time.new.to_i}_#{name.gsub(/\W/, "_")}.migration.rmap.rb"
          
        end
        
      end
      
    end
    
    module Migrate
    
      def self.up
        
      end
    
      def self.down
        
      end
    
    end
    
  end
end
