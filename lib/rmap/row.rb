
require 'json'

module Rmap
  class Row
  
    attr_accessor :id
    
    def initialize(database, table_name, id)
      @database = database
      @table_name = table_name
      @id = id
    end
    
    def fetch(*args)
      @database.client.query("select #{(args.map { |field| "`#{@database.client.escape(field.to_s)}`"}).join(', ')} from `#{@table_name}` where id = '#{id}'", :as => :array).first
    end
    
    def update(hash)
      @database.client.query("update `#{@table_name}` set #{(hash.map{|k,v| "`#{k}`='#{@database.client.escape(v.to_s)}'"}).join(', ')} where id = '#{id}'")
    end
    
    def delete
      @database.client.query("delete from `#{@table_name}` where id = '#{id}'")
    end
    
    def method_missing name, *args
      if @database.table? name
        Table.new(@database, name).join(Table.new(@database, @table_name).eq(:id, @id), *args)
      elsif name.match(/\A.*=\Z/) && @database.method_missing(@table_name).column?(name.to_s.sub(/=\Z/, ""))
        update(name[/\A(.*)=\Z/, 1] => args[0])
      elsif @database.method_missing(@table_name).column? name
        fetch(name).first
      else
        super
      end
    end
    
    def to_s
      @database.client.query("select * from `#{@table_name}` where id = '#{id}'", :as => :hash).first.to_json
    end
    
  end
end
