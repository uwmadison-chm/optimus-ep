# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# Expressions for the ParsedCalculator

module Eprime
  module ParsedCalculator
    class Expr
      # All of our literals, etc will ineherit from Expr. This will imbue
      # them with the magic to work with our unary and binary operators.
      BINARY_OPERATORS=[:+, :-, :*, :/]
      BINARY_OPERATORS.each do |op|
        define_method(op) { |other|
          return BinaryExpr.new(self, op, other)
        }
      end
  
      def concat(other)
        return BinaryExpr.new(self, :&, other)
      end
  
      def -@
        return PrefixExpr.new(:-, self)
      end
    end

    class BinaryExpr < Expr
      
      EVAL_TABLE = {
        :+ => lambda { |lval, rval|
          if lval.kind_of? Numeric and rval.kind_of? Numeric
            return lval+rval
          else
            return "NaN"
          end
        },
        :- => lambda { |lval, rval|
          if lval.kind_of? Numeric and rval.kind_of? Numeric
            return lval-rval
          else
            return "NaN"
          end
        },
      }
      
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
        return EVAL_TABLE[@op].call(lval, rval)
      end
    end

    class PrefixExpr < Expr
      attr_reader :op, :right
      def initialize(op, right)
        @op = op
        @right = right
      end
  
      def to_s
        "#{@op}(#{@right})"
      end
      
      def evaluate(*args)
        table = {
          :- => lambda {|val| 
            return -val if val.kind_of? Numeric
            return "NaN"
          }
        }
        right_value = @right.evaluate(*args)
        return table[@op].call(right_value)
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
    end
  end
end