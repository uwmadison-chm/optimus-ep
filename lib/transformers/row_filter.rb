# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  module Transformers
  
    # Implements a row-wise filter for eprime data.
    # Right now it requires a proc; I'll do something better with a little
    # DSL later.
    class RowFilter
      include Enumerable
    
      def initialize(data, filter)
        @data = data
        @filter = filter
        @computed = nil
      end
    
      def to_eprime_data
        computed
      end
      
      def method_missing(method, *args, &block)
        computed.send method, *args, &block
      end
      
      private
      
      def computed
        return @computed if @computed
        @computed = Eprime::Data.new(@data.columns)
        @data.find_all{ |row|
          match?(row)
        }.each { |row|
          r = @computed.add_row
          r.values = row.values
          r.sort_value = row.sort_value
        }
        return @computed
      end
      
      def match?(row)
        if @filter.is_a? Proc
          return @filter.call(row)
        elsif @filter.is_a? Array
          # @filter will be of the form [col_name, comparator, [value]]
          # only 'equals' is supported for comparators
          if @filter[1].downcase != 'equals'
            raise ArgumentError.new('Only equals is supported in filtering')
          end
          return row[@filter[0]].to_s == @filter[2].to_s
        end
      end
    end
  end
end