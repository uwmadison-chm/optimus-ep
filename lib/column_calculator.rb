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
      @expressions = []
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
    end
        
    def [](index)
      compute_rows!
      return @rows[index]
    end
    
    def size
      @rows.size
    end
    
    def computed_column(name, expression)
      @computed_column_names << name
      @expressions << expression
      @computed_col_name_hash[name] = @computed_column_names.size - 1
      @columns << name
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
    
    def each
      @rows.each_index do |row_index|
        yield self[row_index]
      end
      @rows
    end
    
    protected    
    
    private
    
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
    
    def compute_rows!
      @rows.each do |row|
        @expressions.each_index do |index|
          exp = @expressions[index].dup
          cols = columns_to_replace(exp)
          cols.each do |col|
            col.strip!
            exp.gsub!("{#{col}}", row[col])
          end
          row.computed_data[index] = @@calculator.compute(exp)
        end
      end
    end
    
    
    # Finds an array of strings surrounded by {} characters
    def columns_to_replace(expression)
      return expression.scan(/\{([^}]*)\}/).flatten
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
        if index < @parent.data_columns.size
          return @data[index]
        else
          return @computed_data[index - @parent.data_columns.size - 1]
        end
      end
      
    end
    
    class ExpressionList
      def initialize(data)
        @data = data
        @expr_hash = {}
      end
      
      def []=(name, expr_str)
        @expr_hash[name] = expr_str
        @compute_order = nil
      end
      
      def [](name)
        @expr_hash[name]
      end
      
      private
      def determine_order
        # There's an elegant recursive algorithm to do everything I want
        # It isn't found here
      end
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
  end
end
