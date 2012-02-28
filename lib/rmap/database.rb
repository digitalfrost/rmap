
module Rmap
  class Database
  
    attr_accessor :client
    
    def initialize(conf={})
      @client = Mysql2::Client.new(conf)
      @show_tables_cache
    end
    
    def table?(name)
      if @show_tables_cache.nil?
        @show_tables_cache = @client.query("show tables", :as => :array).map{|a| a[0]}
      end
      @show_tables_cache.include?(name.to_s)
    end
    
    def method_missing name
      Table.new(self, name)
    end
  end
end
