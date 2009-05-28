# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# This is a complete general eprime transforer -- it supports computed columns
# row filters, and multipass operation. In general, once you've read a file in,
# this is probably what you want to use.
# Essentially, this is just a wrapper around the ColumnCalculator,
# RowFilter, and Multipasser classes

require 'eprime'
require 'transformers/column_calculator'
require 'transformers/row_filter'
require 'transformers/multipasser'
require 'parsed_calculator'

module Eprime
  module Transformers
    class BasicTransformer
      def initialize(data)
        @computed_columns = []
        @copydown_columns = []
        @counter_columns = []
        @row_filter = lambda {|r| true}
        @passes = []
        self.data = data
      end
      
      # Delegate to our processed object for... anything we can't already do.
      def method_missing(m, *args, &block)
        processed.send(m, *args, &block)
      end
      
      def data=(data)
        reset_all!
        @data = Eprime::Data.new.merge(data)
      end
      
      def computed_column(*args)
        reset_all!
        @computed_columns << args
      end
      
      def copydown_column(*args)
        reset_all!
        @copydown_columns << args
      end
      
      def counter_column(*args)
        reset_all!
        @counter_columns << args
      end
      
      def row_filter=(filter)
        reset_filtered!
        @row_filter = filter
      end
      
      alias :row_filter :row_filter=
      
      def add_pass(*args)
        reset_all!
        p = Multipasser::Pass.new(*args)
        yield p if block_given?
        @passes << p
        return p
      end
      
      private
      
      # This method should be used instead of accessing @processed directly
      def processed
        compute! and return @processed
      end
      
      def reset_all!
        @computed = nil
        @processed = nil
        return true
      end
      
      def reset_filtered!
        @processed = nil
        return true
      end
      
      def compute!
        return @processed if @processed
        
        if @computed.nil?
          @computed = ColumnCalculator.new
          @computed.data = @data
          @computed_columns.each do |c|
            @computed.computed_column *c
          end
          @copydown_columns.each do |c|
            @computed.copydown_column *c
          end
          @counter_columns.each do |c|
            @computed.counter_column *c
          end
        end
        
        filtered = RowFilter.new(@computed, @row_filter)
        multi = Multipasser.new(filtered)
        @passes.each do |p|
          multi.add_pass(p)
        end
        @processed = Eprime::Data.new.merge(multi)
      end
    end
  end
end