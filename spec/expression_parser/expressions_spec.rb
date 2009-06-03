# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/optimus')
require 'parsed_calculator'

include OptimusTestHelper

NaN = 0.0/0.0

describe Optimus::ParsedCalculator::ExpressionParser do
  before :all do
    @exp = Optimus::ParsedCalculator::ExpressionParser.new
  end
  
  describe "number literals" do
    it "should evaluate number literals" do
      nl = @exp.parse("1")
      nl.should evaluate_to(1)
    end
    
    it "should booleanify number literals" do
      nl = @exp.parse("1")
      nl.to_bool.should be_true
    end
  end
  
  describe "string literals" do
    it "should evaluate string literals" do
      sl = @exp.parse("'foo'")
      sl.should evaluate_to("foo")
    end
    
    it "should interpret full strings as true" do
      sl = @exp.parse("'foo'")
      sl.to_bool.should be_true
    end
  end
  
  describe "prefix expressions" do
    it "should negate numbers" do
      px = @exp.parse("-1")
      px.should evaluate_to(-1)
    end
    
    it "should return NaN when negating strings" do
      px = @exp.parse("-'a'")
      px.should evaluate_to(NaN)
    end
    
    it "should reverse things with not" do
      px = @exp.parse("not 1")
      px.should evaluate_to(false)
      px.to_bool.should be_false
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
      bx.should evaluate_to(NaN)
    end
    
    it "should subtract numbers" do
      bx = @exp.parse("2-1")
      bx.should evaluate_to(1)
    end

    it "should not subtract strings" do
      bx = @exp.parse("1-'a'")
      bx.should evaluate_to(NaN)
    end
    
    it "should multiply numbers" do
      bx = @exp.parse("2*2")
      bx.should evaluate_to(4)
    end
    
    it "should divide numbers" do
      bx = @exp.parse("4/2")
      bx.should evaluate_to(2)
    end
    
    it "should concatenate strings" do
      bx = @exp.parse("'foo' & 'bar'")
      bx.should evaluate_to("foobar")
    end
    
    it "should mod numbers" do
      bx = @exp.parse("5 % 3")
      bx.should evaluate_to(2)
    end

    describe "comparisons" do
      it "should understand equality exprs" do
        bx = @exp.parse("1 = 1")
        bx.should evaluate_to(true)
        bx.to_bool.should be_true
      end
    end

  end
  
end