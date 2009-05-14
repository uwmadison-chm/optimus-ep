# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

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
  
    class ColumnCalculator
      attr_accessor :data
      attr_accessor :sort_expression
      
      include Enumerable
      
      DEFAULT_COL_OPTS = {
        :reset_when => true,
        :count_when => false,
        :count_by => :next
      }
      def initialize(parser = Eprime::ParsedCalculator::ExpressionParser.new)
        @computed_column_names = []
        @computed_columns = {}
        @computed_data = nil
        @parser = parser
        @sort_expression = nil
      end
      
      def data=(data)
        @data = data
        reset!
      end
      
      def sort_expression=(value)
        @sort_expression = Evaluatable.new(value, @parser)
      end
      
      def computed_column(name, start_val, options = {})
        if columns.include?(name)
          raise DuplicateColumnError.new("Can't add duplicate column name #{name}")
        end
        sve = Evaluatable.new(start_val, @parser)
        @computed_column_names << name
        new_opts = DEFAULT_COL_OPTS.merge(options)
        DEFAULT_COL_OPTS.keys.each do |key|
          new_opts[key] = Evaluatable.new(new_opts[key], @parser)
        end
        @computed_columns[name] = ComputedColumn.new(
          name, sve, new_opts
        )
        reset!
      end
      
      def copydown_column(new_name, old_name)
        computed_column(new_name, "{#{old_name}}", :reset_when => "{#{old_name}}")
      end
      
      def counter_column(name, start_val = 1, options = {})
        computed_column(name, start_val, options = {})
      end
      
      def columns
        @data.columns + @computed_column_names
      end
      
      def each(&block)
        computed_data.each(&block)
      end
      
      def [](index)
        computed_data[index]
      end
      
      private
      
      def reset!
        @computed_data = nil
      end
      
      # Strategy: Compute everything and return it. No lazy-evaluation stuff
      # to worry about -- we just return a vanilla Eprime::Data object.
      def computed_data
        return @computed_data if @computed_data
        @computed_data = Eprime::Data.new(columns)
        @computed_data.merge!(@data)
        @computed_data.each do |row|
          @computed_column_names.each do |col|
            row[col] = @computed_columns[col].evaluate(
              :row => row, :computed_columns => @computed_columns
            )
          end
          if @sort_expression.respond_to? :evaluate
            row.sort_value = @sort_expression.evaluate(
              :row => row, :computed_columns => @computed_columns
            )
          end
        end
      end
      
      class ComputedColumn
        COUNTERS = {
          :next => lambda {|val|
            return val.succ if val.respond_to? :succ
            return val + 1
          }
        }
        
        def initialize(name, reset_exp, options = {})
          @name = name
          @reset_exp = reset_exp
          @reset_when = options[:reset_when]
          @count_when = options[:count_when]
          @count_by = options[:count_by]
          @current_value = nil
        end
        
        def evaluate(*args)
          if @reset_when.bool_eval(*args)
            @current_value = @reset_exp.evaluate(*args)
          end
          next_val! if @count_when.bool_eval(*args)
          return @current_value
        end
        
        private
        def next_val!(*args)
          return if @current_value.nil?
          cval = @count_by.evaluate(*args)
          counter = COUNTERS[cval] || cval
          if counter.respond_to?(:call)
            @current_value = counter.call(@current_value)
          else
              @current_value += counter
          end
        end
      end # class ComputedColumn
      
      class Evaluatable
        def initialize(target, parser = nil)
          if target.is_a? String
            @target = parser.parse(target)
          else
            @target = target
          end
        end
        
        def evaluate(*args)
          # Check for magicality
          if @target == :once
            @target = false
            return true
          end
          # If we don't have a call method or an evaluate method, just
          # this as our own default method.
          if not [:call, :evaluate].any? {|msg| @target.respond_to? msg}
            return @target
          end
          if @target.respond_to? :call
            row = (args.last || {})[:row] || []
            return @target.call(row)
          else
            return @target.evaluate(*args)
          end
        end
        
        def bool_eval(*args)
          val = self.evaluate(*args)
          return false if val == ''
          return val
        end
      end# class Evaluatable
    end # class ColumnCalculator
  end
end