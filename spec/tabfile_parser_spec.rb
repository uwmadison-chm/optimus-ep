# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/eprime')
include EprimeTestHelper


shared_examples_for "Eprime::Reader::TabfileParser with sample data" do
  it "should generate and Eprime::Data object" do
    @eprime.should be_an_instance_of(Eprime::Data)
  end

  it "should have columns matching the test set" do
    @eprime.columns.sort.should == STD_COLUMNS.sort
  end

  it "should contain three rows" do
    @eprime.length.should == 3
  end
end

describe Eprime::Reader::TabfileParser do
  
  describe "without column order specified" do
    before :each do
      @file = File.open(EXCEL_FILE, 'r')
      @reader = Eprime::Reader::TabfileParser.new(@file, :skip_lines => 1)
      @eprime = @reader.to_eprime
    end
    
    it_should_behave_like "Eprime::Reader::TabfileParser with sample data"
  end
  
  describe "with column order specified" do
    before :each do
      @file = File.open(EXCEL_FILE, 'r')
      @reader = Eprime::Reader::TabfileParser.new(@file, :skip_lines => 1, :columns => SORTED_COLUMNS)
      @eprime = @reader.to_eprime
    end
   
    it_should_behave_like "Eprime::Reader::TabfileParser with sample data"
    
  end
  
  describe "with data missing from some rows" do
    before :each do
      @file = File.open(BAD_EXCEL_FILE, 'r')
      @reader = Eprime::Reader::TabfileParser.new(@file, :skip_lines => 1)
    end
    
    it "should raise an error when parsing" do
      lambda {
        @reader.to_eprime
      }.should raise_error(Eprime::DamagedFileError)
    end
  end
end