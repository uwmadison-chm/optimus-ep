# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module Optimus
  module Transformers
  
    # Implements a row-wise filter for optimus data.
    # Right now it requires a proc; I'll do something better with a little
    # DSL later.
    class RowFilter
      include Enumerable
    
      def initialize(data, filter)
        @data = data
        @filter = filter
        @computed = nil
      end
    
      def to_optimus_data
        computed
      end
      
      def method_missing(method, *args, &block)
        computed.send method, *args, &block
      end
      
      private
      
      def computed
        return @computed if @computed
        @computed = Optimus::Data.new(@data.columns)
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
        elsif @filter.respond_to? :to_bool
          return @filter.to_bool(:row => row)
        end
      end
    end
  end
end