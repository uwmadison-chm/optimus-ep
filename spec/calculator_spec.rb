# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/eprime')
require 'calculator'

include EprimeTestHelper

describe Eprime::Calculator do
  before :all do
    @calc = Eprime::Calculator.new
  end
  
  it "should compute constants" do
    @calc.compute(es(:const)).should == ev(:const)
  end
  
  it "should allow strings" do
    @calc.compute(es(:str_const)).should == ev(:str_const)
  end
  
  it "should allow string concatentation" #do
  #  @calc.compute(es(:str_cat)).should == ev(:str_cat)
  #end

  it "should not allow concatenating numbers with strings" #do
  #  lambda {
  #    @calc.compute("1 + a")
  #  }.should raise_error
  #end
  
  it "should add" do
    @calc.compute(es(:add)).should == ev(:add)
  end
  
  it "should multiply" do
    @calc.compute(es(:mul)).should == ev(:mul)
  end
  
  it "should handle negation" do
    @calc.compute(es(:add_neg)).should == ev(:add_neg)
  end
  
  it "should handle grouping" do
    @calc.compute(es(:add_mul_group)).should == ev(:add_mul_group)
  end
  
  it "should handle fdiv" do
    @calc.compute(es(:fdiv)).should == ev(:fdiv)
  end
  
  it "should handle fmul" do
    @calc.compute(es(:fmul)).should == ev(:fmul)
  end
  
  it "should handle mod" do
    @calc.compute(es(:mod)).should == ev(:mod)
  end
  
  it "should fail with infix garbage" #do
  #  lambda {
  #    @calc.compute("1 broken 2")
  #  }.should raise_error(RParsec::ParserException)
  #end
end
