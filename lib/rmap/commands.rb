
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
    
    def self.current_migration
      puts db.current_migration
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
          
          up_code_buf = []
          down_code_buf = []
          
          if name.match(/\Aadd_.*_to_(.*?)\Z/)
            table_name = $1
            @columns.each do |column|
              (column_name, type) = column.split(/:/)
              up_code_buf << "  #{table_name}.add :#{column_name}, :#{type}"
              down_code_buf << "  #{table_name}.remove :#{column_name}"
            end
          end
          
          if name.match(/\Aremove_.*_from_(.*?)\Z/)
            table_name = $1
            @columns.each do |column|
              (column_name, type) = column.split(/:/)
              up_code_buf << "  #{table_name}.remove :#{column_name}"
              down_code_buf << "  #{table_name}.add :#{column_name}, :#{type}"
            end
          end
          
          @up_code = up_code_buf.join("\n")
          @down_code = down_code_buf.join("\n")
          
          copy "migration.rmap.rb", "#{Time.new.to_i}_#{name.downcase.strip.gsub(/\W+/, "_")}.migration.rmap.rb", :erb => true
          
        end
        
      end
      
    end

    def self.migrate(options = {})
      db = self.db
      db.migrate(options)
      puts "At migration: #{db.current_migration}"
    end
  
    private
      
    def self.db
      db = Rmap::Database.new
      if Rmap.const_defined? :CONF_ROOT
        db.run("#{Rmap::CONF_ROOT}/conf.rmap.rb")
      end
      db
    end
  
  end
end
