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

require 'transformers/column_calculator'
require 'transformers/row_filter'

module Eprime
  module Transformers
    class Multipasser

      class Pass
        attr_accessor :sort_expression, :row_filter, :computed_columns
        def initialize(sort_expression = "1", row_filter = lambda{|r| true}, computed_columns = [])
          @sort_expression = sort_expression
          @row_filter = row_filter
          @computed_columns = computed_columns
        end
      
        def computed_column(name, expression)
          computed_columns << [name, expression]
        end
      end
    
      include Enumerable
    
      def initialize(data = nil)
        @data = data
        @passes = []
        reset!
      end
    
      def columns
        computed.columns
      end
    
      def data=(data)
        @data = data
        reset!
      end
    
      def add_pass(*args)
        @computed = nil
        if args[0].instance_of? Pass
          p = args[0]
        else
          p = Pass.new(*args)
        end
        @passes << p and return p
      end
    
      def each(&block)
        computed.each(&block)
      end
    
      def [](index)
        computed[index]
      end
    
      private
      def computed
        return @computed if @computed
        if @passes.empty?
          @computed = @data
          return @computed
        end
        @computed = Eprime::Data.new
        # Just add a simple pass if we don't have any...
        @passes.each do |pass|
          # We want to duplicate the data, add a sort expression to it, add
          # computed columns, filter it, and then merge it into the complete
          # dataset.
          #cur_data = @data.to_eprime_data 
          comp_data = ColumnCalculator.new
          comp_data.data = @data
          comp_data.sort_expression = pass.sort_expression
          pass.computed_columns.each do |col|
            name, expr = *col
            comp_data.computed_column(name, expr)
          end
          filtered = RowFilter.new(comp_data, pass.row_filter)
          @computed.merge!(filtered)
        end
        @computed.sort!
        return @computed
      end
      
      def reset!
        @computed = nil
      end
    end
  end
end