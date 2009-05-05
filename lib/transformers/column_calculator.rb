# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require 'calculator'
module Eprime
  module Transformers

    # This implements columnwise and accumulator-style calculations for
    # Eprime data. It generally allows four main kinds of columns:
    # 1: Data columns -- columns backed directly by data
    # 2: Computed columns -- columns computed by numerical operations of other columns in the same row
    # 3: Copydown columns -- Columns equal to the last non-empty value of another column
    # 4: Counter columns -- Columns that change value based on the contents of other columns -- generally to count.
    #
    # It's worth noting: columns may depend on other columns, as long as the dependency isn't circular.
    # Currently, counter columns may behave strangely when used in and using computed columns -- a parser
    # like the computed columns' parser is really needed.
  
    class ColumnCalculator
      attr_writer :data
      attr_reader :columns
    
      COLUMN_TYPES = %w(data_cols computed_cols copydown_cols counter_cols)
      include Enumerable
    
      def initialize()
        @columns = []
        @columns_intern = []
        @column_indexes = {}
        @computed = nil
        @rows = []
        COLUMN_TYPES.each do |type|
          instance_variable_set("@#{type}", [])
        end
        # The name 'sorter' is never used; it's just an arbitrary placeholder
        @sorter = ComputedColumn.new('sorter', Expression.new('1'))
      end
    
      # Makes this into a static Eprime::Data object
      def to_eprime_data
        computed
      end
    
      def data=(data)
        @data = data
        @data_cols = []
        @data.columns.each do |col_name|
          @data_cols << DataColumn.new(col_name, @data)
        end
        set_columns!
      end
    
      def [](index)
        computed[index]
      end
    
      def column_index(col_id)
        return @column_indexes[col_id]
      end
      
      alias :find_column_index :column_index
    
      def column(col_id)
        index = column_index(col_id)
        raise IndexError.new("#{col_id} does not exist") if index.nil?
        return @columns_intern[index]
      end
      
      def size
        @data.size
      end
      
      def columns
        @columns.dup
      end
    
      def computed_column(name, expression)
        @computed_cols << ComputedColumn.new(name, Expression.new(expression))
        set_columns!
      end
    
      def copydown_column(name, copied_name)
        @copydown_cols << CopydownColumn.new(name, copied_name)
        set_columns!
      end
    
      def counter_column(name, options = {})
        @counter_cols << CounterColumn.new(name, options)
        set_columns!
      end
    
      def sort_expression=(expr)
        # The name 'sorter' is utterly arbitrary and never used. It is also
        # not exposed.
        @sorter = ComputedColumn.new('sorter', Expression.new(expr))
        @computed = nil
      end
    
      def sort_expression
        @sorter.to_s
      end
    
      def each(&block)
        computed.each(&block)
      end
    
      def self.compute(numeric_expression)
        @@calculator.compute(numeric_expression)
      end
    
      private
      
      def computed
        @computed || compute_data!
      end
      
      def add_column(column)
        # Raise an error if the column already exists
        if @column_indexes[column.name]
          raise ComputationError.new("#{column.name} already exists!")
        end
        # Save the index
        @column_indexes[@columns_intern.size] = @columns_intern.size
        @column_indexes[column.name] = @columns_intern.size
        @columns_intern << column
        @columns << column.name
      end
      
      def set_columns!
        @columns = []
        @columns_intern = []
        @column_indexes = {}
        COLUMN_TYPES.each do |type|
          ar = instance_variable_get("@#{type}")
          ar.each do |col|
            add_column(col)
          end
        end
        @computed = nil
      end
      
      # Creates the infix calculator -- called at class instantiation time
      def self.make_calculator
        @@calculator = ::Eprime::Calculator.new
      end
      # And the class is instantiated NOW!
      make_calculator
    
      # Run through and compute all data in the set. We need to go in order,
      # because copydown and counter columns depend on the values of previous
      # rows.
      def compute_data!
        #TODO: Parse all the computed columns
        @computed_cols.each do |cc|
          if !cc.expression.expr.respond_to? :call
            #cc.expression.parse_tree = @parser.parse(cc.expression.to_s)
          end
        end
        @computed = Eprime::Data.new(columns)
        @data.each_index do |i|
          row = Row.new(self, @data[i])
          # Loop over each column type -- it's still (slighyly) important that
          # we go over each column type specifically. When counter columns
          # work better, we can rearchitect this a bit.
          COLUMN_TYPES.each do |type|
            ar = instance_variable_get("@#{type}")
            ar.each do |col|
              row.compute(col.name)
            end
          end
          # Set the sort column -- run it as compute_without_check;
          # compute() would check the row's ordinary values for a 
          # 'sorter' column and fail.
          sv = @sorter.compute_without_check(row)
          # make it a float, so we don't need to
          # sort on strings like "-31" (which doesn't work)
          begin
            sv = Kernel.Float(sv)
          rescue ArgumentError
            # If this fails, it's OK -- we just won't convert.
          end
          new_row = @computed.add_row
          new_row.sort_value = sv
          new_row.values = row.values
        end
        @computed
      end
      
      class Column
        attr_accessor :name
      
        def initialize(name)
          @name = name
        end
      
        # This should be overridden by subclasses
        def compute(row, path = [])
          return row[@name]
        end
      end
    
      class DataColumn < Column
        def initialize(name, data)
          @data_index = data.find_column_index(name)
          @data = data
          super(name)
        end
      end
    
      class CopydownColumn < Column
        def initialize(name, copied_name)
          super(name)
          @last_val = ''
          @copied_name = copied_name
        end
      
        def compute(row, path = [])
          if !row[@copied_name].to_s.empty?
            @last_val = row[@copied_name].to_s
          end
          return @last_val
        end
      end
    
      class ComputedColumn < Column
        attr_reader :expression
        
        def initialize(name, expression)
          @expression = expression
          super(name)
        end
      
        def compute(row, path = [])
          return super(row) if super(row)
        
          return compute_without_check(row, path)
        end
      
        def compute_without_check(row, path = [])
          # TODO: Gut this method.
      
          compute_str = @expression.to_s
          if path.include?(@name) 
            raise ComputationError.new("#{compute_str} contains a loop with #{@name} -- can't compute")
          end
          
          # Allow defining the column computation as a lambda
          return @expression.expr.call(row) if @expression.expr.respond_to? :call
            

          column_names = @expression.columns
          column_names.each do |col_name|
            col = row.find_column(col_name)
            val = col.compute(row, path+[@name])
            if val.to_s.empty?
              val = "0"
            end
            compute_str.gsub!("{#{col_name}}", val)
          end
          return ColumnCalculator.compute(compute_str)
        end
      
      end
    
      class CounterColumn < Column
        STANDARD_OPTS = {
          :start_value  => 0, 
          :count_by     => :succ, 
          :count_when   => lambda {|row| true},
          :reset_when   => lambda {|row| false}
        }
        def initialize(name, options)
          @options = STANDARD_OPTS.merge(options)
          @start_value = @options[:start_value]
          @count_by = @options[:count_by]
          @count_when = @options[:count_when]
          @reset_when = @options[:reset_when]
          @current_value = @start_value
          super(name)
        end
      
        def compute(row, path = [])
          if @reset_when.call(row)
            @current_value = @start_value
          end
          if @current_value.respond_to? :call
            @current_value = @current_value.call(row)
          end
        
          if @count_when.call(row)
            if @count_by.respond_to? :call
              @current_value = @count_by.call(@current_value)
            elsif @count_by.is_a?(Symbol) || @count_by.is_a?(String)
              @current_value = @current_value.send(@count_by)
            else
              @current_value = @current_value + @count_by
            end
          end
        
          return @current_value
        end
      end
    
      class Row
        attr_reader :values
        attr_accessor :sort_value
      
        def initialize(parent, rowdata)
          @parent = parent
          @rowdata = rowdata
          @values = []
          # Add all the data columns to @values
          rowdata.columns.each do |dcol_name|
            index = @parent.column_index(dcol_name)
            rd = rowdata[dcol_name]
            begin
              ci = values[index]
            rescue Exception => e
              raise e
            end
            @values[index] = rowdata[dcol_name]
          end
          @sort_value = 1
        end
      
        def [](col_id)
          if @parent.column_index(col_id).nil?
            raise IndexError.new("#{col_id} does not exist")
          end
          return @values[@parent.column_index(col_id)]
        end
      
        def find_column(column_name)
          @parent.column(column_name)
        end
      
        def columns
          @parent.columns
        end
      
      
        # Recursively compute this column name and every column on which it depends
        def compute(col_name)
          raise ArgumentError.new("compute requires a column name") unless col_name.is_a? String
        
          index = @parent.column_index(col_name)
          col = @parent.column(col_name)
          val = col.compute(self)
          @values[index] = val
          return val
        end
      
        def <=>(other_row)
          @sort_value <=> other_row.sort_value
        end
      end
    
    
      class Expression
        attr_reader :columns
        attr_reader :expr
        attr_accessor :parse_tree
      
        COLUMN_FINDER = /\{([^}]*)\}/ # Finds strings like {foo} and {bar}
        def initialize(expr_string)
          @expr = expr_string
          unless expr_string.is_a? Proc
            @columns = find_columns(expr_string).freeze 
          end
        end
      
        def to_s
          @expr.to_s.dup
        end
      
        private
        def find_columns(str)
          return str.scan(COLUMN_FINDER).flatten
        end
      end
    
      class ComputationError < Exception
      
      end
    end
  end
end
