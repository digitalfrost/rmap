
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
          
          copy "migration.rmap.rb", "#{Time.new.to_i}_#{name.downcase.strip.gsub(/\W+/, "_")}.migration.rmap.rb"
          
        end
        
      end
      
    end

    
    def self.migrate(options = {})
      db = Rmap::Database.new
    
      if Rmap.const_defined? :CONF_ROOT
        db.run("#{Rmap::CONF_ROOT}/conf.rmap.rb")
      end
      
      if !db.table? :rmap_vars
        db.create :rmap_vars
        db.rmap_vars.add :key, :string
        db.rmap_vars.add :value, :binary
      end
      
      if db.rmap_vars.key_eq(:current_migration).count == 0
        db.rmap_vars.insert(:key => :current_migration, :value => 0)
        current_migration = 0
      else
        current_migration = db.rmap_vars.key_eq(:current_migration).first.value.to_i
      end
      
      migrations = Dir.new("#{Rmap::CONF_ROOT}/migrations/").to_a.find_all{|file| ::File.file? "#{Rmap::CONF_ROOT}/migrations/#{file}" }.map{ |file| Rmap::Migration.new("#{Rmap::CONF_ROOT}/migrations/#{file}") }.sort {|l,r| l.schema_version <=> r.schema_version}
      
      if !options[:to].nil?
        to = options[:to].to_i
        found = false
        migrations.each do |migration|
          if migration.schema_version == to
            found = true
            break
          end
        end
        
        if !found
          raise "No such migration '#{to}' exists"
        end
        
        if to > current_migration
          migrations.each do |migration|
            if migration.schema_version <= current_migration
              next
            end
            
            if migration.schema_version <= to
              puts "up: #{migration.schema_version}"
              db.run &migration.up_block
            else
              break
            end
          end
          #todo: .to_s should not need to be specified
          db.rmap_vars.key_eq(:current_migration).value = to.to_s
        elsif to < current_migration
          migrations.reverse.each do |migration|
            if migration.schema_version > current_migration
              next
            end
            if migration.schema_version > to
              puts "down: #{migration.schema_version}"
              db.run &migration.down_block
            else
              break
            end
          end
          #todo: .to_s should not need to be specified
          db.rmap_vars.key_eq(:current_migration).value = to.to_s
        else
          raise "already at migration #{to}"
        end
        
        #work out direction (up|down)
      elsif migrations.count > 0
        migrations.each do |migration|
          if migration.schema_version > current_migration
            puts "up: #{migration.schema_version}"
            db.run &migration.up_block
          end
        end
        #todo: .to_s should not need to be specified
        db.rmap_vars.key_eq(:current_migration).value = migrations.last.schema_version.to_s
      end
           
    end
    
  end
end
