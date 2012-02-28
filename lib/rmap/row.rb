
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
      @database.client.query("update `#{@table_name}` set #{(hash.map{|k,v| "`#{k}`='#{@database.client.escape(v)}'"}).join(', ')} where id = '#{id}'")
    end
    
    def delete
      @database.client.query("delete from `#{@table_name}` where id = '#{id}'")
    end
    
    def method_missing name, *args
      if @database.table? name
        Table.new(@database, name).join(Table.new(@database, @table_name).eq(:id, @id), *args)
      elsif @database.method_missing(@table_name).column? name
        fetch(name).first
      elsif @database.method_missing(@table_name).column?(name.to_s.sub(/=\Z/, "")) && name.match(/\A(.*)=\Z/)
        update($1 => args[0])
      else
        super
      end
    end
    
  end
end
