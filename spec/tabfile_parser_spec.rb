# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/optimus')
include OptimusTestHelper


shared_examples_for "Optimus::Reader::TabfileParser with sample data" do
  it "should generate and Optimus::Data object" do
    @optimus.should be_an_instance_of(Optimus::Data)
  end

  it "should have columns matching the test set" do
    @optimus.columns.sort.should == STD_COLUMNS.sort
  end

  it "should contain three rows" do
    @optimus.length.should == 3
  end
end

describe Optimus::Reader::TabfileParser do
  
  describe "without column order specified" do
    before :each do
      @file = File.open(EXCEL_FILE, 'r')
      @reader = Optimus::Reader::TabfileParser.new(@file, :skip_lines => 1)
      @optimus = @reader.to_optimus
    end
    
    it_should_behave_like "Optimus::Reader::TabfileParser with sample data"
  end
  
  describe "with column order specified" do
    before :each do
      @file = File.open(EXCEL_FILE, 'r')
      @reader = Optimus::Reader::TabfileParser.new(@file, :skip_lines => 1, :columns => SORTED_COLUMNS)
      @optimus = @reader.to_optimus
    end
   
    it_should_behave_like "Optimus::Reader::TabfileParser with sample data"
    
  end
  
  describe "with data missing from some rows" do
    before :each do
      @file = File.open(BAD_EXCEL_FILE, 'r')
      @reader = Optimus::Reader::TabfileParser.new(@file, :skip_lines => 1)
    end
    
    it "should raise an error when parsing" do
      lambda {
        @reader.to_optimus
      }.should raise_error(Optimus::DamagedFileError)
    end
  end
end