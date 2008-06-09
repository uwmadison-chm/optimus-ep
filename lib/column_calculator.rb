# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require 'calculator'

module Eprime
  class ColumnCalculator
    attr_writer :data
    attr_reader :columns
    
    # Order is important here -- data columns must come first!
    COLUMN_TYPES = %w(data_cols computed_cols)
    include Enumerable
    
    def initialize
      @columns = []
      @columns_intern = []
      @column_indexes = {}
      @rows = []
      COLUMN_TYPES.each do |type|
        instance_variable_set("@#{type}", [])
      end
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
      compute_data! unless @computed
      return @rows[index]
    end
    
    def column_index(col_id)
      if col_id.is_a? Fixnum
        return (col_id >= 0 and col_id < @columns.size) ? col_id : nil
      end
      return @column_indexes[col_id]
    end
    
    def column(col_id)
      index = column_index(col_id)
      raise IndexError.new("#{col_id} does not exist") if index.nil?
      return @columns_intern[index]
    end
    
    def size
      @data.size
    end
    
    def computed_column(name, expression)
      @computed_cols << ComputedColumn.new(name, Expression.new(expression))
      set_columns!
    end
    
    def each
      @rows.each_index do |row_index|
        yield self[row_index]
      end
      @rows
    end
    
    def self.compute(numeric_expression)
      @@calculator.compute(numeric_expression)
    end
    
    private
    
    def add_column(column)
      # Raise an error if the column already exists
      if @column_indexes[column.name]
        raise ComputationError.new("#{column.name} already exists!")
      end
      # Save the index
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
      @computed = false
    end
    
    # Creates the infix calculator -- called at class instantiation time
    def self.make_calculator
      @@calculator = ::Eprime::Calculator.new
    end
    make_calculator
    
    def compute_data!
      @rows = []
      @data.each_index do |row_index|
        row = Row.new(self, @data[row_index])
        COLUMN_TYPES.each do |type|
          ar = instance_variable_get("@#{type}")
          ar.each do |col|
            row.compute(col.name)
          end
        end
        @rows << row
      end
      @computed = true
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
    
    class ComputedColumn < Column
      attr_accessor :expression
      
      def initialize(name, expression)
        @expression = expression
        super(name)
      end
      
      def compute(row, path = [])
        return super(row) if super(row)
        
        compute_str = @expression.to_s
        if path.include?(@name) 
          raise ComputationError.new("#{compute_str} contains a loop with #{@name} -- can't compute")
        end

        column_names = @expression.columns
        column_names.each do |col_name|
          col = row.find_column(col_name)
          val = col.compute(row, path+[@name])
          compute_str.gsub!("{#{col_name}}", val)
        end
        return ::Eprime::ColumnCalculator.compute(compute_str)
      end
    end
    
    class Row
      attr_reader :computed_data
      
      def initialize(parent, rowdata)
        @parent = parent
        @rowdata = rowdata
        @computed_data = []
        # Add all the data columns to computed_data
        rowdata.columns.each do |dcol_name|
          index = @parent.column_index(dcol_name)
          @computed_data[index] = rowdata[dcol_name]
        end
      end
      
      def [](col_id)
        if @parent.column_index(col_id).nil?
          raise IndexError.new("#{col_id} does not exist")
        end
        return @computed_data[@parent.column_index(col_id)]
      end
      
      def find_column(column_name)
        @parent.column(column_name)
      end
      
      
      # Recursively compute this column name and every column on which it depends
      def compute(col_name)
        raise ArgumentError.new("compute requires a column name") unless col_name.is_a? String
        
        index = @parent.column_index(col_name)
        col = @parent.column(col_name)
        @computed_data[index] = col.compute(self)
        return @computed_data[index]
      end
      
      private
      
    end
    
    class Expression
      attr_reader :columns
      
      COLUMN_FINDER = /\{([^}]*)\}/ # Finds strings like {foo} and {bar}
      def initialize(expr_string)
        @expr = expr_string
        @columns = find_columns(expr_string).freeze
      end
      
      def to_s
        @expr.dup
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
