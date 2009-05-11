# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
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
require 'expression_parser/expressions'

module Eprime
  module ParsedCalculator
    include RParsec
    class ExpressionParser
      extend RParsec::Parsers
      include RParsec::Parsers

      def initialize
        @operators = RParsec::Operators.new(
          %w{+ - * / % & ( ) not and or = != > >= < <=}
        )
        expr = nil
        lazy_expr = lazy { expr }
        atom = (
          token(:str) { |lex| StringLiteral.new(lex) } |
          token(:number) { |lex| NumberLiteral.new(lex) } |
          token(:column) { |lex| ColumnReference.new(lex) } )
        
        lit = atom | (@operators['('] >> lazy_expr << @operators[')'])
        
        # Follows hte standard C 
        table = RParsec::OperatorTable.new.
          prefix(@operators['-'] >>   lambda {|a| -a}, 50).
          prefix(@operators['not'] >> lambda {|a| a.logical_not}, 50).
          infixl(@operators['*'] >>   lambda {|a, b| a*b}, 30).
          infixl(@operators['/'] >>   lambda {|a, b| a/b}, 30).
          infixl(@operators['%'] >>   lambda {|a, b| a%b}, 30).
          infixl(@operators['+'] >>   lambda {|a, b| a+b}, 27).
          infixl(@operators['-'] >>   lambda {|a, b| a-b}, 27).
          infixl(@operators['&'] >>   lambda {|a, b| a&b}, 25).
          infixl(@operators['>'] >>   lambda {|a, b| a>b}, 17).
          infixl(@operators['>='] >>  lambda {|a, b| a>=b}, 17).
          infixl(@operators['<'] >>   lambda {|a, b| a<b}, 17).
          infixl(@operators['<='] >>  lambda {|a, b| a<=b}, 17).
          infixl(@operators['='] >>   lambda {|a, b| a.eq(b)}, 15).
          infixl(@operators['!='] >>  lambda {|a, b| a.neq(b)}, 15).
          infixl(@operators['and'] >> lambda {|a, b| a.logical_and(b)}, 5).
          infixl(@operators['or'] >>  lambda {|a, b| a.logical_or(b)}, 4)
        
        expr = RParsec::Expressions.build(lit, table)
        
        lexeme = tokenizer.lexeme(whitespaces) << eof
        @parser = lexeme.nested(expr << eof)
      end
      
      def parse(str)
        begin
          @parser.parse(str)
        rescue Exception
          raise
        end
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
  end
end