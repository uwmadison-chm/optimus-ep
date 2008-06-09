# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# Calculator code adapted from rparsec infix calculator demo
# at http://docs.codehaus.org/display/JPARSEC/Ruby+Parsec
# rparsec (C) Ben Yu

require 'rubygems'
require 'rparsec'
include RParsec

module Eprime
  class Calculator
    include Parsers
    include Functors
    
    Mod = lambda { |x, y| x.to_i % y.to_i }
    Eql = lambda { |x, y| x.to_s == y.to_s }
    
    def initialize
      ops = OperatorTable.new.
        infixl(char('+') >> Plus, 20).
        infixl(char('-') >> Minus, 20).
        infixl(char('*') >> Mul, 40).
        infixl(char('/') >> Div, 40).
        infixl(char('%') >> Mod, 40).
        prefix(char('-') >> Neg, 60)
      expr = nil
      float_parser = number.map(&To_f)
      grouping_parser = char('(') >>(lazy{expr})<< char(')')
      term = alt(float_parser, grouping_parser)
      delim = whitespace.many_
      expr = delim >> Expressions.build(term, ops, delim)
      @parser = expr
    end
    
    def compute(expression)
      ans = @parser.parse(expression)
      if (ans - ans.to_i) == 0
        ans = ans.to_i
      end
      return ans.to_s
    end
  end
end