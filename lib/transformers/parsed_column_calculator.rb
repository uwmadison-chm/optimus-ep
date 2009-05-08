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
  
    # note: to determine if number: ^(((\d{1,3})(,\d{3})*)|(\d+))(.\d+)?$
    # Better: If you've got funny numbers, coerce into numericness. Make
    # coercion very robust.
  
    class ParsedColumnCalculator
      attr_accessor :data
      
      include Enumerable
      
      def initialize(parser = Eprime::ParsedCalculator::ExpressionParser.new)
        @computed_column_names = []
        @computed_columns = {}
        @computed_data = nil
        @parser = parser
      end
      
      def data=(data)
        @data = data
        reset!
      end
      
      def computed_column(name, expression_str)
        # TODO handle duplicate names
        @computed_column_names << name
        @computed_columns[name] = @parser.parse(expression_str)
        reset!
      end
      
      def columns
        @data.columns + @computed_column_names
      end
      
      def each(&block)
        computed_data.each(&block)
      end
      
      private
      
      def reset!
        @computed_data = nil
      end
      
      def computed_data
        return @computed_data if @computed_data
        @computed_data = Eprime::Data.new(columns)
        @computed_data.merge!(@data)
        @computed_data.each do |row|
          @computed_column_names.each do |col|
            row[col] = @computed_columns[col].evaluate
          end
        end
      end
    end    
  end
end