# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# A two-stage parser that should be both faster and more flexible than the
# one-stage regex hack currently in use.
# Major difference: this will return parse trees that need to be evaluated
# by passing in a row's worth of data, instead of directly evaluating a string
# after substituting row data.

require 'rubygems'
require 'rparsec'
require 'pp'

module Eprime
  module ParsedCalculator
    include RParsec
    class ExpressionParser
      extend RParsec::Parsers
      include RParsec::Parsers

      def initialize
        @operators = RParsec::Operators.new(%w{+ - * / & ( )})
        expr = nil
        lazy_expr = lazy { expr }
        atom = (
          token(:str) { |lex| StringLiteral.new(lex) } |
          token(:number) { |lex| NumberLiteral.new(lex) } |
          token(:column) { |lex| ColumnReference.new(lex) } )
        
        lit = atom | (@operators['('] >> lazy_expr << @operators[')'])
        
        table = RParsec::OperatorTable.new.
          prefix(@operators['-'] >> lambda {|a| -a}, 50).
          infixl(@operators['*'] >> lambda {|a, b| a*b}, 30).
          infixl(@operators['/'] >> lambda {|a, b| a/b}, 30).
          infixl(@operators['+'] >> lambda {|a, b| a+b}, 10).
          infixl(@operators['-'] >> lambda {|a, b| a-b}, 10).
          infixl(@operators['&'] >> lambda {|a, b| a.concat(b)},5) #dishwasher
        
        expr = RParsec::Expressions.build(lit, table)
        
        lexeme = tokenizer.lexeme(whitespaces) << eof
        @parser = lexeme.nested(expr << eof)
      end
      
      def parse(str)
        @parser.parse(str)
      end
      
      private
      
      def tokenizer
        return (
          string_literal.token(:str) |
          number.token(:number) |
          column_reference.token(:column) |
          @operators.lexer
        )
      end
      
      def string_literal
        (char("'") >> (not_char("'")|str("''")).many.fragment << char("'"))
      end
      
      def column_reference
        (char('{') >> (string('\}')|not_char('}')).many_.fragment << char('}'))
      end
    end
    
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
      attr_reader :left, :op, :right
      def initialize(left, op, right)
        @left = left
        @op = op
        @right = right
      end
      
      def to_s
        "(#{@left} #{@op} #{@right})"
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
    end
    
    class NumberLiteral < Expr
      def initialize(token)
        @token = token
      end
      
      def to_s
        @token
      end
    end
    
    class StringLiteral < Expr
      def initialize(token)
        @token = token
      end
      
      def to_s
        "'#{@token}'"
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