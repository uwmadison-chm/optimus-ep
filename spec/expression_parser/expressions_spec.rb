# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')
require 'parsed_calculator'

include EprimeTestHelper

describe Eprime::ParsedCalculator::ExpressionParser do
  before :all do
    @exp = Eprime::ParsedCalculator::ExpressionParser.new
  end
  
  describe "number literals" do
    it "should evaluate number literals" do
      nl = @exp.parse("1")
      nl.should evaluate_to(1)
    end
  end
  
  describe "string literals" do
    it "should evaluate string literals" do
      sl = @exp.parse("'foo'")
      sl.should evaluate_to("foo")
    end
  end
  
  describe "prefix expressions" do
    it "should negate numbers" do
      px = @exp.parse("-1")
      px.should evaluate_to(-1)
    end
    
    it "should return NaN when negating strings" do
      px = @exp.parse("-'a'")
      px.should evaluate_to("NaN")
    end
  end
  
  describe "binary expressions" do
    it "should add numbers" do
      bx = @exp.parse("1+1")
      bx.should evaluate_to(2)
    end
    
    it "should add numbers with grouping" do
      bx = @exp.parse("(1+1)+1")
      bx.should evaluate_to(3)
    end

    it "should not add strings" do
      bx = @exp.parse("1+'a'")
      bx.should evaluate_to("NaN")
    end
    
    it "should subtract numbers" do
      bx = @exp.parse("2-1")
      bx.should evaluate_to(1)
      
    end

  end
end