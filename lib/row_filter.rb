# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Eprime
  
  # Implements a row-wise filter for eprime data.
  # Right now it requires a proc; I'll do something better with a little
  # DSL later.
  class RowFilter
    include Enumerable
    
    def initialize(data, filter)
      @data = data
      @filter = filter
    end
    
    def to_eprime_data
      Eprime::Data.new().merge!(self)
    end
    
    def each
      @data.each do |row|
        yield row if match?(row)
      end
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