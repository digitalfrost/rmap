
module Rmap
  class Database
    
    def initialize(conf={:username => 'root'})
      @conf = conf
    end
    
    def client
      if @client.nil?
        @client = Mysql2::Client.new(@conf)
      end
      @client
    end
    
    def host(host)
      @conf[:host] = host
    end
    
    def username(username)
      @conf[:username] = username
    end
    
    def database(database)
      @conf[:database] = database
    end
    
    def bindings
      binding
    end
    
    def run(file_path)
      instance_eval(::File.open(file_path).read, file_path)
    end
    
    def table?(name)
      table_names.include?(name.to_s)
    end
    
    def method_missing name, *args
      if table_names.include? name.to_s
        Table.new(self, name)
      else
        super(name, *args)
      end
    end
    
    def create(name)
      @table_names = nil
      client.query("create table `#{name}`(id int unsigned not null auto_increment primary key)")
    end
    
    def table_names
      if @table_names.nil?
        @table_names = client.query("show tables", :as => :array).map{|a| a[0]}
      end
      @table_names
    end
    
  end
end
