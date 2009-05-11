# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/eprime')
require 'parsed_calculator'

include EprimeTestHelper

describe Eprime::ParsedCalculator::ExpressionParser do
  before :all do
    @exp = Eprime::ParsedCalculator::ExpressionParser.new
  end
  
  it "should parse positive integers" do
    @exp.should round_trip("1")
  end
  
  it "should parse floats" do
    @exp.should round_trip("1.1")
  end
  
  it "should not parse barewords" do
    @exp.should_not parse_successfully("foo")
  end
    
  it "should parse single-quoted strings" do
    @exp.should round_trip("'fixation'")
  end
  
  it "should parse strings with two single-quotes as one single-quote" do
    @exp.should round_trip("'foo''bar'")
  end
  
  it "should parse column names" do
    @exp.should round_trip("{foo}")
  end
  
  it "should parse column names with { included" do
    @exp.should round_trip("{foo{bar}")
  end
  
  it "should parse column names with \\} included" do
    @exp.should round_trip('{foo\}bar}')
  end
  
  it "should parse + as binary operator with numbers" do
    @exp.should parse_as('1 + 1', '(1 + 1)')
  end
  
  it "should parse + as a binary operator without spaces" do
    @exp.should parse_as("1+1", "(1 + 1)")
  end
  
  it "should parse + as binary operator with strings" do
    @exp.should parse_as("'a' + 1", "('a' + 1)")
  end
  
  it "should parse + as binary operator with columns" do
    @exp.should parse_as("{foo} + 1", "({foo} + 1)")
  end
  
  it "should left-associatively group with +" do
    @exp.should parse_as("1 + 1 + 1", "((1 + 1) + 1)")
  end
  
  it "should parse with specified grouping" do
    @exp.should parse_as("1 + (1 + 1)", "(1 + (1 + 1))")
  end
  
  # We've done all the complex tests with + -- another associative binary
  # operator. I'm assuming the others work as well. This will just shorthand
  # that testing.
  describe "with binary operators" do
    before :all do
      @ops = %w(+ - * / % & > >= < <= = != and or)
    end
    
    it "should parse binary operators" do
      @ops.each do |op|
        @exp.should round_trip("(1 #{op} 1)")
      end
    end
  end

  it "should give * higher precedence than +" do
    @exp.should parse_as("1 + 1 * 1", "(1 + (1 * 1))")
  end
  
  it "should give * higher precedence than binary -" do
    @exp.should parse_as("1 - 1 * 1", "(1 - (1 * 1))")
  end

  it "should give / the same precedence as *" do
    # This means we'll just use left-associtivity rules...
    @exp.should parse_as("1 / 1 * 1", "((1 / 1) * 1)")
    @exp.should parse_as("1 * 1 / 1", "((1 * 1) / 1)")
  end
  
  it "should parse - as a unary prefix operator" do
    @exp.should parse_as("-1", "-(1)")
  end
  
  it "should give negation higher precedence than *" do
    @exp.should parse_as("-1*1", "(-(1) * 1)")
  end
  
  it "should parse 'not' as a unary prefix operator" do
    @exp.should parse_as("not 1", "not (1)")
  end
end