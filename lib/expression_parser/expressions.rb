# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# Expressions for the ParsedCalculator
require 'expression_parser/evaluators'

module Optimus
  module ParsedCalculator
    NaN = 0.0/0.0
    class Expr
      # All of our literals, etc will ineherit from Expr. This will imbue
      # them with the magic to work with our unary and binary operators.
      BINARY_OPERATORS=[:+, :-, :*, :/, :%, :&, :>, :>=, :<, :<=]
      BINARY_OPERATORS.each do |op|
        define_method(op) { |other|
          return BinaryExpr.new(self, op, other)
        }
      end
      
      def logical_and(other)
        return BinaryExpr.new(self, :and, other)
      end
      
      def logical_or(other)
        return BinaryExpr.new(self, :or, other)
      end
      
      def eq(other)
        return BinaryExpr.new(self, "=".to_sym, other)
      end
      
      def neq(other)
        return BinaryExpr.new(self, '!='.to_sym, other)
      end
      
      # Prefixes
      def -@
        return PrefixExpr.new(:-, self)
      end
      
      def logical_not
        return KeywordPrefixExpr.new(:not, self)
      end
      
      def to_bool(*args)
        val = evaluate(*args)
        return false if val == ''
        return val
      end
    end

    class BinaryExpr < Expr
      include Evaluators::Binary
      
      attr_reader :left, :op, :right
      def initialize(left, op, right)
        @left = left
        @op = op
        @right = right
      end
  
      def to_s
        "(#{@left} #{@op} #{@right})"
      end
      
      def evaluate(*args)
        lval = @left.evaluate(*args)
        rval = @right.evaluate(*args)
        return OpTable[@op].call(lval, rval)
      end
    end

    class PrefixExpr < Expr
      include Evaluators::Prefix
      attr_reader :op, :right
      def initialize(op, right)
        @op = op
        @right = right
      end
  
      def to_s
        "#{@op}(#{@right})"
      end
      
      def evaluate(*args)
        rval = @right.evaluate(*args)
        return OpTable[@op].call(rval)
      end
      
    end
    
    class KeywordPrefixExpr < PrefixExpr
      def to_s
        "#{@op} (#{@right})"
      end
    end

    class NumberLiteral < Expr
      def initialize(token)
        @token = token
      end
  
      def to_s
        @token
      end
      
      def evaluate(*args)
        @token.to_f
      end
    end

    class StringLiteral < Expr
      
      def initialize(token)
        @token = token
      end
  
      def to_s
        "'#{@token}'"
      end
      
      def evaluate(*args)
        @token
      end
    end

    class ColumnReference < Expr
      def initialize(name)
        @name = name
      end
  
      def to_s
        "{#{@name}}"
      end
      
      def evaluate(*args)
        options = args.last || {}
        row = options[:row] || {}
        computed_columns = options[:computed_columns] || {}
        seen_columns = options[:seen_columns] || []
        if seen_columns.include?(@name)
          raise EvaluationLoopError.new(
            "Loop error - #{@name} depends on itself: [#{seen_columns.join(', ')}]"
          )
        end
        
        if !row[@name] and computed_columns.include?(@name)
          row[@name] = computed_columns[@name].evaluate(
            :row => row, 
            :computed_columns => computed_columns,
            :seen_columns => ([@name] + seen_columns)
          )
        end
        return magic_cast(row[@name])
      end
      
      private
      def magic_cast(value)
        new_val = value.to_s.strip
        new_val = new_val.to_f if numlike?(new_val)
        return new_val
      end
      
      def numlike?(value)
        value.to_s =~ /^-?\d+\.?\d*$/
      end
    end # class ColumnReference
  end
end