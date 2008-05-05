# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  
  # Raised when columns were specified at initialization time, and a novel
  # column is added. Generally, this is an indication that Something is Funny.
  class ColumnAddedWarning < Exception
    # We want to be able to get the index out of this
    attr_reader :index
    def initialize(message, index)
      @index = index
      super(message)
    end
  end
  
  # A generalized data structure for eprime files -- essentially just
  # a table structure.
  # I should be able to say:
  # e_data = Eprime::Data.new
  # e_data[0][0] for the first row / col
  # e_data[0]['ExperimentName'] for the experiment name
  # e_data[0][0] = "foo"
  # e_data.add_row
  # e_data[0]['kitteh'] = "cheezburger"
  # For querying:
  # Indexing numerically out of bounds should raise an exception
  # Indexing textwise out of bounds should raise an exception
  # For setting:
  # Indexing numerically out of bounds should raise an exception
  # Indexing textwise out of bounds should add a column
  # So... you might reasonably do
  # r = e_data.new_row()
  # r['Stim.OnsetTime'] = '3521'
  # One last thing: if you care about column ordering, but may be adding
  # data in an arbitrary order (example: reading E-Prime log files),
  # you can force a column order by passing an array of strings to
  # Eprime::Data.new  
  
  class Data
    
    attr_reader :columns
    
    def initialize(columns = [])
      @rows = []
      @columns = []
      @column_hash = {}
      @columns_set_in_initialize = false
      if (columns.length > 0)
        columns.each do |col|
          idx = self.find_or_add_column_index(col)
        end
        @columns_set_in_initialize = true
      end
    end
    
    # We mostly delegate to our rows array
    def method_missing(method, *args, &block)
      @rows.send method, *args, &block
    end
    
    def add_row
      row = Row.new(self)
      @rows << row
      return row
    end
    
    def find_column_index(col_id)
      if (col_id.is_a?(Fixnum) or col_id.to_i.to_s == col_id)
        return col_id.to_i
      end
      # Short-circuit this 
      @column_hash[col_id] if @column_hash[col_id]
    end
    
    def find_or_add_column_index(col_id)
      index_id = find_column_index(col_id)
      return index_id if index_id
      # In this case, we're adding a column...
      @columns << col_id
      index = @columns.length - 1
      @column_hash[col_id] = index
      if @columns_set_in_initialize
        raise ColumnAddedWarning.new("Warning: Added column #{col_id} after specifying columns at init", index)
      end
      return index
    end
    
    class Row
      def initialize(parent)
        @data = []
        @parent = parent
      end
      
      def [](index)
        num_index = @parent.find_column_index(index)
        unless (num_index.is_a?(Fixnum) and @parent.columns.length > num_index)
          raise IndexError.new("Column #{num_index} does not exist")
        end
        return @data[num_index]
      end
      
      def []=(index, value)
        num_index = @parent.find_or_add_column_index(index)
        unless (@parent.columns.length > num_index)
          raise IndexError.new("Column #{num_index} does not exist")
        end
        @data[num_index] = value
      end
      
      def values
        vals = []
        @parent.columns.each_index do |i|
          vals[i] = @data[i]
        end
        return vals
      end
      
    end
  end
  
end