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
    
    include Enumerable
    
    def initialize
      @computed_column_names = []
      @computed_col_name_hash = {}
      @expressions = {}
      @columns = []
      @rows = []
    end
    
    def data_columns
      @data.columns
    end
    
    def data=(data)
      @data = data
      set_rows!(@data)
      @columns = @data.columns + @computed_column_names
      @computed = false
    end
        
    def [](index)
      compute_data! unless @computed
      return @rows[index]
    end
    
    def size
      @rows.size
    end
    
    def computed_column(name, expression)
      @computed_column_names << name
      @expressions[name] = Expression.new(expression)
      
      @computed_col_name_hash[name] = @computed_column_names.size - 1
      @columns << name
      @computed = false
    end
    
    def column_index(col_id)
      if col_id.is_a? Fixnum
        return (col_id < @columns.size) ? col_id : nil
      end
      # First, see if it's a data column
      index = @data.find_column_index(col_id)
      if index.nil?
        # Find the colum in our own hash and add the number of data columns to it
        # if necessary
        index = @computed_col_name_hash[col_id]
        index += @data.columns.size if index
      end
      return index
    end
    
    def is_computed?(col_id)
      index = column_index(col_id)
      if index.nil? or index >= @data.columns.size
        return true
      else
        return false
      end
    end
    
    def computed_index(col_id)
      index = column_index(col_id)
      return nil if index.nil?
      if index >= @data.columns.size
        return index - (@data.columns.size)
      end
    end
    
    def expression(name)
      @expressions[name]
    end
    
    def each
      @rows.each_index do |row_index|
        yield self[row_index]
      end
      @rows
    end
    
    def compute(numeric_expression)
      @@calculator.compute(numeric_expression)
    end
    
    protected    
    
    private
    
    # Creates the infix calculator -- called at class instantiation time
    def self.make_calculator
      @@calculator = ::Eprime::Calculator.new
    end
    make_calculator
    
    def set_rows!(data)
      @rows = []
      data.each do |r|
        @rows << Row.new(r, self)
      end
    end
    
    def compute_data!
      @rows.each_index do |row_index|
        @computed_column_names.each do |col|
          @rows[row_index].compute(col)
        end
      end
      @computed = true
    end
        
    
    class Row
      attr_reader :computed_data
      
      def initialize(rowdata, parent)
        @data = rowdata
        @parent = parent
        @computed_data = []
      end
      
      def [](col_id)
        index = @parent.column_index(col_id)
        raise IndexError.new("Column #{col_id} does not exist") if index.nil?
        if @parent.is_computed?(index)
          c_index = @parent.computed_index(index)
          return @computed_data[c_index]
        else
          return @data[index]
        end
      end
      
      
      # Recursively compute this column name and every column on which it depends
      def compute(col_name, path = [])
        raise ArgumentError.new("compute requires a column name") unless col_name.is_a? String
        # The end case for this recursive function
        # Also handles the error condition where
        if self[col_name]
          return self[col_name]
        end

        expr = @parent.expression(col_name)
        compute_str = expr.to_s

        # Ensure the path doesn't contain us
        if path.include?(col_name) 
          raise ComputationError.new("#{compute_str} contains a loop with #{col_name} -- can't compute")
        end

        expr.columns.each do |col|
          val = compute(col, path + [col_name])
          compute_str.gsub!("{#{col}}", val.to_s)
        end
        
        comp_index = @parent.computed_index(col_name)
        val = @parent.compute(compute_str)
        @computed_data[comp_index] = val
        return @computed_data[comp_index]
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
