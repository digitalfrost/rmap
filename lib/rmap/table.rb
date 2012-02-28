
module Rmap
  class Table
    BINARY_FILTER_METHODS = {
      'eq' => lambda {|left,right| "#{left} = #{right}"},
      'ne' => lambda {|left,right| "#{left} != #{right}"}, 
      'lt' => lambda {|left,right| "#{left} < #{right}"}, 
      'gt' => lambda {|left,right| "#{left} > #{right}"}, 
      'le' => lambda {|left,right| "#{left} <= #{right}"}, 
      'ge' => lambda {|left,right| "#{left} >= #{right}"}, 
      'contains' => lambda {|left,right| "#{left} like concat('%', #{right}, '%')"}, 
      'begins_with' => lambda {|left,right| "#{left} like concat('%', #{right})"}, 
      'ends_with' => lambda {|left,right| "#{left} like concat(#{right}, '%')"}
    }
    
    attr_accessor :name
    
    def initialize(database, name)
      @database = database
      @name = name
      @binary_filter_methods_args = {}
      Table::BINARY_FILTER_METHODS.each {|name, block| @binary_filter_methods_args[name] = []}
      @join_list = []
      @order_by_list = []
    end
  
    Table::BINARY_FILTER_METHODS.each do |name,block|
      define_method name do |left, right|
        @binary_filter_methods_args[name].push([left,right])
        self
      end
    end
    
    def join(table, options = {})
      @join_list.push({:table => table, :options => options});
      self
    end
    
    def order_by(sql_exression, desc = false)
      @order_by_list.push([sql_exression, desc])
      self
    end
    
    def column?(name)
      @database.client.query("describe #{@name} #{name}").count > 0
    end
    
    def method_missing name, *args
      if @database.table? name
        Table.new(@database, name).join(self, *args)
      elsif column? name
        all.map{|row| row.fetch(name).first}
      elsif column?(name.to_s.sub(/=\Z/, "")) && name.match(/\A(.*)=\Z/)
        all.each{|row| row.update($1 => args[0])}
      else
        super
      end
    end
    
    def format_sql(sql)
      out_buffer = []
      sql = sql.to_s
      while sql.length > 0
        if sql.match(/\A(\s+|\d+\.\d+|\d+|\w+\()(.*)/)
          out_buffer.push($1)
          sql = $2
        elsif sql.match(/\A(\w+)\.(\w+)(.*)/)
          out_buffer.push("`#{$1}`.`#{$2}`")
          sql = $3
        elsif sql.match(/\A(\w+)(.*)/)
          out_buffer.push("`#{@name}`.`#{$1}`")
          sql = $2
        else
          sql.match(/\A(.)(.*)/)
          out_buffer.push($1)
          sql = $2
        end
      end 
      out_buffer.join
    end
    
    def quote(data)
      "'" + @database.client.escape(data.to_s) +  "'"
    end
    
    def generate_filter_conditions_sql
      and_sql = []
      Table::BINARY_FILTER_METHODS.each do |name, block|
        @binary_filter_methods_args[name].each do |args|
          or_sql = []
          if args[0].class.name == 'Array'
            args[0].each do |left|
              or_sql.push(block.call(format_sql(left.to_s), quote(args[1])))
            end
          elsif args[1].class.name == 'Array'
            args[1].each do |right|
              or_sql.push(block.call(format_sql(args[0].to_s), quote(right)))
            end
          else
            or_sql.push(block.call(format_sql(args[0].to_s), quote(args[1])))
          end
          and_sql.push("(" + or_sql.join(' or ') + ")")
        end
      end
      @join_list.each do |join|
        and_sql.push(join[:table].generate_filter_conditions_sql)
      end
      and_sql.join(' and ')
    end
    
    def generate_table_list_sql
      out = []
      out.push(name)
      @join_list.each do |join|
        table_list_sql = join[:table].generate_table_list_sql
        if table_list_sql != ''
          out.push(table_list_sql)
        end
      end
      out.join(', ')
    end
    
    def generate_from_sql
      "from " + generate_table_list_sql
    end
    
    def generate_join_condition_sql(table1, table2, foreign_key)
      if !foreign_key.nil?
        if table2.column? foreign_key
          "#{table1.name}.id = #{table2.name}.#{foreign_key}"
        else
          "#{table1.name}.#{foreign_key} = #{table2.name}.id"
        end
      else
        if table2.column? "#{table1.name}_id"
          "#{table1.name}.id = #{table2.name}.#{table1.name}_id"
        else
          "#{table1.name}.#{table2.name}_id = #{table2.name}.id"
        end
      end
    end
    
    def generate_inner_join_conditions_sql
      out = []
      @join_list.each do |join|
        out.push(generate_join_condition_sql(self, join[:table], join[:options][:using]))
        inner_join_conditions_sql = join[:table].generate_inner_join_conditions_sql
        if inner_join_conditions_sql != ''
          out.push(inner_join_conditions_sql)
        end
      end
      out.join(" and ")
    end
    
    def generate_where_sql
      out = []
      inner_join_conditions_sql = generate_inner_join_conditions_sql
      if inner_join_conditions_sql != ''
        out.push inner_join_conditions_sql
      end
      filter_conditions_sql = generate_filter_conditions_sql
      if filter_conditions_sql != ''
        out.push filter_conditions_sql
      end
      out = out.join(' and ')
      if out != ''
        out = "where #{out}"
      end
      out
    end
    
    def generate_group_by_sql
      if @join_list.count > 0
        "group by #{name}.id"
      end
    end
    
    def generate_order_by_sql
      out = []
      @order_by_list.each do |order_by|
        (sql_expression, desc) = order_by
        if desc
          out.push "#{format_sql(sql_expression)} desc"
        else
          out.push "#{format_sql(sql_expression)} asc"
        end
      end
      @join_list.each do |join|
        order_by_sql = join[:table].generate_order_by_sql
        if order_by_sql != ''
          out.push(order_by_sql)
        end
      end
      out = out.join(', ')
      if out != ''
        out = "order by #{out}"
      end
      out
    end
    
    def generate_select_sql(expression_list_sql, limit = nil)
      if !limit.nil?
        limit_sql = "limit #{limit}"
      else 
        limit_sql = ''
      end
      "select #{format_sql(expression_list_sql)} #{generate_from_sql} #{generate_where_sql} #{generate_group_by_sql} #{generate_order_by_sql} #{limit_sql}"
    end
    
    def count(limit = nil)
      @database.client.query(generate_select_sql('id', limit)).count
    end
    
    def all(limit = nil)
      out = []
      @database.client.query(generate_select_sql('id', limit), :as => :hash).each do |row|
        out.push(Row.new(@database, @name, row['id']))
      end
      out
    end
    
    def first
      all(1).first
    end
    
    def update(hash)
      all.each {|row| row.update(hash)}
    end
    
    def delete
      all.each {|row| row.delete}
    end
    
    def insert(hash)
      @database.client.query("insert into `#{@name}`(#{(hash.map{|k,v| "`#{k}`"}).join(', ')}) values(#{(hash.map{|k,v| quote(v)}).join(', ')})")
    end
    
    def sum(sql_expression, limit = nil)
      out = 0
      @database.client.query(generate_select_sql("sum(#{sql_expression})", limit), :as => :array).each{|row| out += row.first}
      out
    end
    
  end
end
