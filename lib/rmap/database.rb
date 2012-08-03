
require 'mysql2'

module Rmap
  class Database
    
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
    
    def method_missing name, *args
      Table.new(self, name)
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
    
  end
end
