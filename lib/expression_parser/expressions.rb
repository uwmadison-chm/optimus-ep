# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# Expressions for the ParsedCalculator
require 'expression_parser/evaluators'

module Eprime
  module ParsedCalculator
    NaN = 0.0/0.0
    class Expr
      # All of our literals, etc will ineherit from Expr. This will imbue
      # them with the magic to work with our unary and binary operators.
      BINARY_OPERATORS=[:+, :-, :*, :/, :%, :&]
      BINARY_OPERATORS.each do |op|
        define_method(op) { |other|
          return BinaryExpr.new(self, op, other)
        }
      end
  
      def -@
        return PrefixExpr.new(:-, self)
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
        
      end
    end
  end
end