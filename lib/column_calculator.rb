# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  class ColumnCalculator
    attr_writer :data
    attr_reader :columns
    
    include Enumerable
    
    def initialize
      @computed_column_names = []
      @computed_col_name_hash = {}
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
      return @rows[index]
    end
    
    def size
      @rows.size
    end
    
    def each
      @rows.each do |row|
        yield row
      end
      @rows
    end
    
    def computed_column(name, expression)
      @computed_column_names << name
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
    
    private
    
    def set_rows!(data)
      @rows = []
      data.each do |r|
        @rows << Row.new(r, self)
      end
    end
    
    
    class Row
      def initialize(rowdata, parent)
        @data = rowdata
        @parent = parent
      end
      
      def [](col_id)
        index = @parent.column_index(col_id)
        raise IndexError.new("Column #{col_id} does not exist") if index.nil?
        if index < @parent.data_columns.size
          return @data[index]
        else
          return nil
        end
      end
    end
  end
end
