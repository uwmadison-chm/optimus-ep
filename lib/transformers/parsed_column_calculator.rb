# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require 'calculator'
require 'parsed_calculator'
module Eprime
  module Transformers

    # This implements columnwise operations with a new shiny parser 

    # Column types:
    # 1: Data columns -- columns backed directly by data
    # 2: Computed columns -- columns computed by numerical operations of other columns in the same row
  
    class ParsedColumnCalculator
      attr_accessor :data
      
      include Enumerable
      
      def initialize(parser = Eprime::ParsedCalculator::ExpressionParser.new)
        @computed_column_names = []
      end
      
      def computed_column(name, expression)
        @computed_column_names << name
      end
      
      def columns
        @data.columns + @computed_column_names
      end
      
      def each(&block)
        @data.each(&block)
      end
    end    
  end
end