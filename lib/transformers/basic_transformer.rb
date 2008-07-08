# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
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
require 'column_calculator'
require 'row_filter'
require 'multipasser'

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
        reset!
        @data = Eprime::Data.new.merge(data)
      end
      
      def computed_column(*args)
        reset!
        @computed_columns << args
      end
      
      def copydown_column(*args)
        reset!
        @copydown_columns << args
      end
      
      def counter_column(*args)
        reset!
        @counter_columns << args
      end
      
      def row_filter=(filter)
        reset!
        @row_filter = filter
      end
      
      def add_pass(*args)
        reset!
        p = Eprime::Multipasser::Pass.new(*args)
        yield p if block_given?
        @passes << p
        return p
      end
      
      private
      
      # This method should be used instead of accessing @processed directly
      def processed
        compute! and return @processed
      end
      
      def reset!
        @processed = nil
        return true
      end
      
      def compute!
        return @processed if @processed
        cc = ColumnCalculator.new
        cc.data = @data
        @computed_columns.each do |c|
          cc.computed_column *c
        end
        @copydown_columns.each do |c|
          cc.copydown_column *c
        end
        @counter_columns.each do |c|
          cc.counter_column *c
        end
        filtered = RowFilter.new(cc, @row_filter)
        multi = Multipasser.new(filtered)
        @passes.each do |p|
          multi.add_pass(p)
        end
        @processed = Eprime::Data.new.merge(multi)
      end
    end
  end
end