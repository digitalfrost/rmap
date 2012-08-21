
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
      'ends_with' => lambda {|left,right| "#{left} like concat('%', #{right})"}, 
      'begins_with' => lambda {|left,right| "#{left} like concat(#{right}, '%')"},
      'year_eq' => lambda {|left,right| "year(#{left}) = #{right}"},
      'year_ne' => lambda {|left,right| "year(#{left}) != #{right}"}, 
      'year_lt' => lambda {|left,right| "year(#{left}) < #{right}"}, 
      'year_gt' => lambda {|left,right| "year(#{left}) > #{right}"}, 
      'year_le' => lambda {|left,right| "year(#{left}) <= #{right}"}, 
      'year_ge' => lambda {|left,right| "year(#{left}) >= #{right}"},
      'month_eq' => lambda {|left,right| "month(#{left}) = #{right}"},
      'month_ne' => lambda {|left,right| "month(#{left}) != #{right}"}, 
      'month_lt' => lambda {|left,right| "month(#{left}) < #{right}"}, 
      'month_gt' => lambda {|left,right| "month(#{left}) > #{right}"}, 
      'month_le' => lambda {|left,right| "month(#{left}) <= #{right}"}, 
      'month_ge' => lambda {|left,right| "month(#{left}) >= #{right}"},
      'day_eq' => lambda {|left,right| "day(#{left}) = #{right}"},
      'day_ne' => lambda {|left,right| "day(#{left}) != #{right}"}, 
      'day_lt' => lambda {|left,right| "day(#{left}) < #{right}"}, 
      'day_gt' => lambda {|left,right| "day(#{left}) > #{right}"}, 
      'day_le' => lambda {|left,right| "day(#{left}) <= #{right}"}, 
      'day_ge' => lambda {|left,right| "day(#{left}) >= #{right}"},
      'hour_eq' => lambda {|left,right| "hour(#{left}) = #{right}"},
      'hour_ne' => lambda {|left,right| "hour(#{left}) != #{right}"}, 
      'hour_lt' => lambda {|left,right| "hour(#{left}) < #{right}"}, 
      'hour_gt' => lambda {|left,right| "hour(#{left}) > #{right}"}, 
      'hour_le' => lambda {|left,right| "hour(#{left}) <= #{right}"}, 
      'hour_ge' => lambda {|left,right| "hour(#{left}) >= #{right}"},
      'minute_eq' => lambda {|left,right| "minute(#{left}) = #{right}"},
      'minute_ne' => lambda {|left,right| "minute(#{left}) != #{right}"}, 
      'minute_lt' => lambda {|left,right| "minute(#{left}) < #{right}"}, 
      'minute_gt' => lambda {|left,right| "minute(#{left}) > #{right}"}, 
      'minute_le' => lambda {|left,right| "minute(#{left}) <= #{right}"}, 
      'minute_ge' => lambda {|left,right| "minute(#{left}) >= #{right}"},
      'second_eq' => lambda {|left,right| "second(#{left}) = #{right}"},
      'second_ne' => lambda {|left,right| "second(#{left}) != #{right}"}, 
      'second_lt' => lambda {|left,right| "second(#{left}) < #{right}"}, 
      'second_gt' => lambda {|left,right| "second(#{left}) > #{right}"}, 
      'second_le' => lambda {|left,right| "second(#{left}) <= #{right}"}, 
      'second_ge' => lambda {|left,right| "second(#{left}) >= #{right}"},
    }
    
    attr_accessor :name, :page
    
    def initialize(database, name)
      @database = database
      @name = name
      @binary_filter_methods_args = {}
      Table::BINARY_FILTER_METHODS.each {|name, block| @binary_filter_methods_args[name] = []}
      @join_list = []
      @order_by_list = []
      @page = 1
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
      @database.client.query("describe #{@name} `#{name}`").count > 0
    end
    
    def method_missing name, *args
      table = self
      if @database.table? name
        Table.new(@database, name).join(self, *args)
      elsif column? name
        all.map{|row| row.fetch(name).first}
      elsif column?(name.to_s.sub(/=\Z/, "")) && name.match(/\A(.*)=\Z/)
        all.each{|row| row.update($1 => args[0])}
      elsif name.match /\A(.*?)_(#{BINARY_FILTER_METHODS.keys.join('|')})\Z/
        @binary_filter_methods_args[$2].push([$1.split(/_or_/),args[0]])
        self
      elsif @database.instance_eval{!@scopes[table.name].nil? && !@scopes[table.name][name].nil?}
        instance_exec *args, &@database.instance_eval{@scopes[table.name][name]}
        self
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
        if table2.column? "#{to_singular(table1.name)}_id"
          "#{table1.name}.id = #{table2.name}.#{to_singular(table1.name)}_id"
        else
          "#{table1.name}.#{to_singular(table2.name)}_id = #{table2.name}.id"
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
    
    def generate_limit_sql
      @page_size.nil? ? "" : "limit #{(@page - 1) * @page_size}, #{@page_size}"
    end
    
    def generate_select_sql(expression_list_sql, without_limit = false)
      "select #{format_sql(expression_list_sql)} #{generate_from_sql} #{generate_where_sql} #{generate_group_by_sql} #{generate_order_by_sql} #{without_limit ? "" : generate_limit_sql}"
    end
    
    def explain
      generate_select_sql('id').strip
    end
    
    def count
      @database.client.query(generate_select_sql('id')).count
    end
    
    def all
      out = []
      @database.client.query(generate_select_sql('id'), :as => :hash).each do |row|
        out.push(Row.new(@database, @name, row['id']))
      end
      out
    end
    
    def each &block
      all.each &block
      nil
    end
    
    def first
      all.first
    end
    
    def update(hash)
      all.each {|row| row.update(hash)}
    end
    
    def delete
      each {|row| row.delete}
    end
    
    def insert(hash)
      @database.client.query("insert into `#{@name}`(#{(hash.map{|k,v| "`#{k}`"}).join(', ')}) values(#{(hash.map{|k,v| quote(v)}).join(', ')})")
      @database.client.last_id
    end
    
    def sum(sql_expression, limit = nil)
      out = 0
      @database.client.query(generate_select_sql("sum(#{sql_expression})", limit), :as => :array).each{|row| out += row.first}
      out
    end
    
    def drop
      eval("@table_names = nil", @database.bindings)
      @database.client.query("drop table `#{@name}`")
    end
    
    def add(name, type, options = {})
      
      if !@database.table? @name
        @database.create @name
      end
    
      case type
      when :string
        @database.client.query("alter table `#{@name}` add `#{name}` varchar(255) not null")
      when :text
        @database.client.query("alter table `#{@name}` add `#{name}` longtext not null")
      when :binary
        @database.client.query("alter table `#{@name}` add `#{name}` longblob not null")
      when :integer
        @database.client.query("alter table `#{@name}` add `#{name}` int signed not null")
      when :foreign_key
        @database.client.query("alter table `#{@name}` add `#{name}` int unsigned not null")
        @database.client.query("alter table `#{@name}` add index(`#{name}`)")
      when :date
        @database.client.query("alter table `#{@name}` add `#{name}` date not null")
      when :datetime
        @database.client.query("alter table `#{@name}` add `#{name}` datetime not null")
      when :boolean
        @database.client.query("alter table `#{@name}` add `#{name}` enum('true', 'false') not null")
      when :decimal
        @database.client.query("alter table `#{@name}` add `#{name}` decimal not null")
      end
    end
    
    def remove(name)
      @database.client.query("alter table `#{@name}` drop `#{name}`")
    end
    
    def column_names
      @database.client.query("describe `#{@name}`", :as => :hash).map {|row| row['Field']}
    end
    
    def to_s
      all.to_s
    end
    
    def define_scope(name, &block)
      table = self
      @database.instance_eval do
        if @scopes[table.name].nil?
          @scopes[table.name] = {}
        end
        @scopes[table.name][name.to_sym] = block
      end
    end
    
    def paginate(page_size = 10)
      @page_size = page_size
      self
    end
    
    def set_page(page)
      @page = page.to_i
      self
    end
    
    def page_count
      count_without_limit = @database.client.query(generate_select_sql('id', true)).count
      if !@page.nil?
        (count_without_limit.to_f / @page_size).ceil
      else
        count_without_limit > 0 ? 1 : 0
      end
    end
    
    private
    
    def to_singular(value)
      if value.to_s.match /\A(.*)ies\Z/
        "#{$1}y"
      elsif value.to_s.match /\A(.*ss)es\Z/
        $1
      else
        value.to_s.gsub(/s\Z/, "")
      end
    end
    
  end
end
