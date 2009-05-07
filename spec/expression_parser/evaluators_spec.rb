# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')

require 'parsed_calculator'
require 'expression_parser/evaluators'
include EprimeTestHelper
include Eprime::ParsedCalculator::Evaluators

describe Prefix do
  describe 'negation' do
    before :all do
      @neg = Prefix::Neg
    end

    it "should negate numbers" do
      @neg.call(1).should == -1
    end
    
    it "should return NaN when negating non-numbers" do
      @neg.call("a").should be_nan
    end
  end
end

describe Binary do
  describe 'addition' do
    before :all do
      @plus = Binary::Plus
    end
    
    it "should add numbers" do
      @plus.call(1, 1).should == 2
    end
    
    it "should return NaN when adding non-numbers" do
      @plus.call(1, 'a').should be_nan
    end
  end
  
  describe 'subtraction' do
    before :all do
      @minus = Binary::Minus
    end
    
    it "should subtract numbers" do
      @minus.call(2, 1).should == 1
    end
    
    it "should return NaN when subtracting non-numbers" do
      @minus.call(2, 'a').should be_nan
    end
  end
  
  describe 'multiplication' do
    before :all do
      @times = Binary::Times
    end
    
    it "should multiply numbers" do
      @times.call(2, 2).should == 4
    end
    
    it "should return NaN when multiplying non-numbers" do
      @times.call(2, 'a').should be_nan
    end
  end
  
  describe 'division' do
    before :all do
      @div = Binary::Div
    end
    
    it "should divide numbers" do
      @div.call(4, 2).should == 2
    end
    
    it "should return NaN when dividing non-numbers" do
      @div.call(2, 'a').should be_nan
    end
    
    it "should perform floating point division" do
      res = 1.0/3.0
      @div.call(1,3).should == res
    end
    
    it "should return NaN when dividing by 0" do
      @div.call(2,0).should be_nan
    end
  end
  
  describe 'concatenation' do
    before :all do
      @cat = Binary::Concat
    end
    
    it "should concatenate strings" do
      @cat.call("foo", "bar").should == "foobar"
    end
    
    it "should concatenate numbers" do
      @cat.call("foo", 2).should == "foo2"
    end
    
    it "should concatenate nil" do
      @cat.call("foo", nil).should == "foo"
    end
  end
  
  describe "modulo" do
    before :all do
      @mod = Binary::Mod
    end
    
    it "should mod ints" do
      @mod.call(5, 3).should == 2
    end
    
    it "should not mod strings" do
      @mod.call(5, 'a').should be_nan
    end
  end
end
