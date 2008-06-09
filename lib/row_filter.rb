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
    
    def each
      @data.each do |row|
        yield row if @filter.call(row)
      end
    end
  end
end