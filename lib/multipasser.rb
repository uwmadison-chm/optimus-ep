# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# This class provides the ability for a dataset to be 'exploded' into more
# rows than originally existed. For example, you might have:
# fixation_time stim_time
# 10            30
# 100           130
#
# And want to change it to:
# presented_object  time
# fixation          10
# stimulus          30
# fixation          100
# stimulus          130

require 'column_calculator'
require 'row_filter'

module Eprime
  class Multipasser

    class Pass
      attr_accessor :sort_expression, :row_filter, :computed_columns
      def initialize(sort_expression = "1", row_filter = lambda{|r| true}, computed_columns = [])
        @sort_expression = sort_expression
        @row_filter = row_filter
        @computed_columns = []
      end
      
      def computed_column(name, expression)
        computed_columns << [name, expression]
      end
    end
    
    include Enumerable
    
    def initialize(data = nil)
      @data = data
      @passes = []
      @computed = false
    end
    
    def data=(data)
      @data = data
    end
    
    def each
      compute! unless @computed
      @all_data.each do |row|
        yield row
      end
    end
    
    def add_pass(*args)
      p = Pass.new(*args)
      @passes << p and return p
    end
    
    def [](index)
      compute! unless @computed
      return @all_data[index]
    end
    
    private
    def compute!
      @all_data = Eprime::Data.new
      # Just add a simple pass if we don't have any...
      add_pass if @passes.empty?
      @passes.each do |pass|
        # We want to duplicate the data, add a sort expression to it, add
        # computed columns, filter it, and then merge it into the complete
        # dataset.
        cur_data = @data.to_eprime_data 
        comp_data = ColumnCalculator.new
        comp_data.data = cur_data
        comp_data.sort_expression = pass.sort_expression
        pass.computed_columns.each do |col|
          name, expr = *col
          comp_data.computed_column(name, expr)
        end
        filtered = RowFilter.new(comp_data, pass.row_filter)
        @all_data.merge!(comp_data)
      end
      @all_data = Eprime::Data.new.merge(@all_data.sort)
      
      # 1: Create an empty Eprime::Data object @all_data
      # 2: For each pass:
      #  a: Duplicate @data
      #  b: Create a ColumnCalculator object, 
      #  c: Apply a row filter to it
      #  d: Merge the filtered data into @all_data
      # 3: Sort @acc
    end
    
  end
end