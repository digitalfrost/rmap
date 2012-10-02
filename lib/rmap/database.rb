
require 'mysql2'

module Rmap
  class Database
  
    def self.create(database, connection = {})
      connection = {:host => "localhost", :username => "root", :password => ""}.merge connection
      Mysql2::Client.new(connection).query("create database `#{database}`");
      connection[:database] = database
      self.new(connection)
    end
    
    def self.drop(database, connection = {})
      connection = {:host => "localhost", :username => "root", :password => ""}.merge connection
      Mysql2::Client.new(connection).query("drop database `#{database}`");
    end
    
    def self.list(connection = {})
      connection = {:host => "localhost", :username => "root", :password => ""}.merge connection
      Mysql2::Client.new(connection).query("show databases", :as => :array).map{|a| a[0]}
    end
    
    def self.exists?(database, connection = {})
      list(connection).include? database.to_s
    end
    
    def initialize(connection={}, &block)
      self.connection = connection
      if !block.nil?
        instance_eval(&block)
      end
      @scopes = {}
    end
    
    def connection=(connection)
      @connection = {:host => "localhost", :username => "root", :password => ""}.merge connection
      close
      @table_names = nil
    end
    
    def client
      if @client.nil?
        @client = Mysql2::Client.new(@connection)
      end
      @client
    end
    
    def close
      if !@client.nil?
        @client.close
      end
      @client = nil
    end
    
    def bindings
      binding
    end
    
    def run(file_path = nil, &block)
      if !file_path.nil?
        instance_eval(::File.open(file_path).read, file_path)
      end
      if !block.nil?
        instance_eval(&block)
      end
    end
    
    def table?(name)
      table_names.include?(name.to_s)
    end
    
    def table(name)
      Table.new(self, name.to_s)
    end
    
    def method_missing name, *args
      table(name)
    end
    
    def create(name)
      @table_names = nil
      client.query("create table `#{name}`(id int unsigned not null auto_increment primary key) engine = InnoDB")
    end
    
    def table_names
      if @table_names.nil?
        @table_names = client.query("show tables", :as => :array).map{|a| a[0]}
      end
      @table_names
    end
    
    def start_transaction
      client.query("start transaction")
    end
    
    def commit_transaction
      client.query("commit")
    end
    
    def rollback_transaction
      client.query("rollback")
    end
    
    def current_migration
      if !table? :rmap_vars
        rmap_vars.add :key, :string
        rmap_vars.add :value, :binary
      end
      
      if rmap_vars.key_eq(:current_migration).count == 0
        rmap_vars.insert(:key => :current_migration, :value => 0)
        0
      else
        rmap_vars.key_eq(:current_migration).first.value.to_i
      end
    end
    
    def migrate(options = {})
      migrations_dir = !options[:migrations_dir].nil? ? (options[:migrations_dir].match(/\/\Z/) ? options[:migrations_dir] : "#{options[:migrations_dir]}/") : "#{Rmap::CONF_ROOT}/migrations/"
      
      current_migration = self.current_migration
      
      migrations = Dir.new(migrations_dir).to_a.find_all{|file| ::File.file? "#{migrations_dir}#{file}" }.map{ |file| Rmap::Migration.new("#{migrations_dir}#{file}") }.sort {|l,r| l.schema_version <=> r.schema_version}
      
      if migrations.count == 0
        raise "There are currently no migrations."
      end
      
      if options[:to].nil?
        to = migrations.last.schema_version
        if to == current_migration
          raise "There are no are more migrations that can be applied."
        end
      elsif options[:to].to_s == 'previous'
        if current_migration == 0
          raise "No migrations have been applied."
        elsif current_migration == migrations.first.schema_version
          to = 0
        else
          migrations.each_with_index do |migration, i|
            if current_migration == migration.schema_version
              to = migrations[i - 1]
              break
            end
          end
        end
      elsif options[:to].to_s == 'next'
        if current_migration == 0
          to = migrations.first.schema_version
        elsif current_migration == migrations.last.schema_version
          raise "There are no are more migrations that can be applied."
        end
        migrations.each_with_index do |migration, i|
          if current_migration == migration.schema_version
            to = migrations[i + 1]
            break
          end
        end
      else
        found = false
        to = options[:to].to_i
        
        if to == current_migration
          raise "Already at migration #{to}"
        end
        
        if to != 0
          migrations.each do |migration, i|
            if migration.schema_version == to
              found = true
              break
            end
          end
          
          if !found
            raise "No such migration '#{to}' exists"
          end
        end
      end
      
      if to > current_migration
        migrations.each do |migration|
          if migration.schema_version <= current_migration
            next
          end
          
          if migration.schema_version <= to
            run &migration.up_block
          else
            break
          end
        end
      else
        migrations.reverse.each do |migration|
          if migration.schema_version > current_migration
            next
          end
          if migration.schema_version > to
            run &migration.down_block
          else
            break
          end
        end
      end
      
      rmap_vars.key_eq(:current_migration).value = to
      
      self
    end
    
  end
end
