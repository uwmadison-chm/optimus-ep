# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
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
    @exp.should round_trip("'foo'")
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
end