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
    
    def initialize(columns = [], options = {})
      @options = options || []
      @rows = []
      @columns = []
      @column_hash = {}
      @columns_set_in_initialize = false
      if (columns && columns.length > 0)
        add_columns!(columns)
        @columns_set_in_initialize = true
      end
    end
    
    # Returns a new Eprime::Data object containing the data from this
    # and all other data sets
    def merge(*datasets)
      cols = [self, *datasets].map { |d| d.columns }.flatten.uniq
      d = Eprime::Data.new(cols)
      return d.merge!(self, *datasets)
    end
    
    # Combine more Eprime::Data objects into this one, in-place
    def merge!(*datasets)
      datasets.each do |source|
        add_columns!(source.columns)
        if source.columns == self.columns
          # The fast option
          source.each do |row|
            r = self.add_row
            r.sort_value = row.sort_value
            r.values = row.values
          end
        else
          # The general case option
          source.each do |row|
            r = self.add_row
            row.columns.each do |col|
              r[col] = row[col]
            end
            r.sort_value = row.sort_value
          end
        end
      end
      return self
    end
    
    def sort!(&block)
      @rows = @rows.sort(&block)
    end
    
    def sort_by!(&block)
      @rows = @rows.sort_by(&block)
    end
    
    def dup
      Eprime::Data.new().merge!(self)
    end
    
    alias :to_eprime_data :dup
    
    # We mostly delegate to our rows array
    def method_missing(method, *args, &block)
      @rows.send method, *args, &block
    end
    
    def add_row()
      row = Row.new(self)
      @rows << row
      return row
    end
    
    def find_column_index(col_id)
      @column_hash[col_id]
    end
    
    def find_or_add_column_index(col_id)
      index_id = find_column_index(col_id)
      # If index_id was a string, nil means we may want to add it. If it's a
      # numeric index, we want to return nil from here -- we're not gonna add 
      # unnamed indexes.
      return index_id if index_id or col_id.is_a?(Fixnum)
      # In this case, we're adding a column...
      index = @columns.size
      @columns << col_id
      @column_hash[col_id] = index
      @column_hash[index] = index
      if @columns_set_in_initialize and not @options[:ignore_warnings]
        raise ColumnAddedWarning.new(
          "Error: Added column #{col_id} after specifying columns at init", 
          index
        )
      end
      return index
    end
    
    private
    def add_columns!(col_arr)
      col_arr.each do |c|
        find_or_add_column_index(c)
      end
    end
    
    class Row
      attr_accessor :sort_value
      
      def initialize(parent, data = [], sort_value = 1)
        @parent = parent
        @data = data
        # Ensure it's comparable
        @sort_value = sort_value
      end
      
      def [](index)
        num_index = @parent.find_column_index(index)
        unless (num_index.is_a?(Fixnum) and @parent.columns.length>num_index)
          raise IndexError.new("Column #{num_index} does not exist")
        end
        return @data[num_index]
      end
      
      def []=(index, value)
        num_index = @parent.find_or_add_column_index(index)
        if num_index.nil?
          raise IndexError.new("Column #{num_index} does not exist")
        end
        @data[num_index] = value
      end
      
      def <=>(other)
        @sort_value <=> other.sort_value
      end
      
      def columns
        @parent.columns
      end
      
      def values
        return @data
      end
      
      def values=(ar)
        @data = ar
      end
    end
  end
  
end