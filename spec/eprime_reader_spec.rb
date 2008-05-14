# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/eprime')
include EprimeTestHelper

describe Eprime::Reader do
  before(:each) do
    @reader = Eprime::Reader.new
  end
  

  it "should raise error when reading nil" do
    lambda {
      @reader.input = (nil)
    }.should raise_error
  end
  
  it "should raise when filetype is unknown" do
    File.open(UNKNOWN_FILE) do |file|
      lambda { @reader.input = (file) }.should raise_error(Eprime::UnknownTypeError)
    end
  end
  
  describe "with log files" do
    before :each do
      @file = File.open(LOG_FILE, 'r')
    end
  
    it "should not raise errors on reading" do
      lambda {
        @reader.input = @file
      }.should_not raise_error
    end
    
    it "should detect log files" do
      @reader.input = (@file)
      @reader.type.should == :log
    end

    it "should return the Eprime::Reader::LogfileParser" do
      @reader.input = @file
      @reader.parser.should be_an_instance_of(Eprime::Reader::LogfileParser)
    end
    
    it "should make a non-empty Eprime::Data object" do
      @reader.input = @file
      data = @reader.eprime_data
      data.length.should > 0
      data.columns.sort.should == SORTED_COLUMNS
    end
    
    it "should respect options" do
      @reader.input = @file
      @reader.options = {:columns => SHORT_COLUMNS}
      lambda {
        @reader.parser.options.should == {:columns => SHORT_COLUMNS}
      }.should raise_error
    end
  end
  
  describe "with excel tsv files" do
    
    before :each do
      @file = File.open(EXCEL_FILE)
    end
  
    it "should detect excel csv files" do
      @reader.input = @file
      @reader.type.should == :excel
    end
    
    it "should resutn the Eprime::Reader::ExcelParser" do
      @reader.input = @file
      @reader.parser.should be_an_instance_of(Eprime::Reader::ExcelParser)
    end
    
    it "should make a non-empty Eprime::Data object" do
      @reader.input = @file
      data = @reader.eprime_data
      data.length.should > 0
      data.columns.sort.should == SORTED_COLUMNS
    end
    
  end
  
  describe "with eprime tsv files" do
    before :each do
      @file = File.open(EPRIME_FILE)
    end
    
    it "should detect eprime csv files" do
      @reader.input = @file
      @reader.type.should == :eprime
    end
    
    it "should return the Eprime::Reader::EprimetabParser" do
      @reader.input = @file
      @reader.parser.should be_an_instance_of(Eprime::Reader::EprimetabParser)
    end
    
    it "should make a non-empty Eprime::Data object" do
      @reader.input = @file
      data = @reader.eprime_data
      data.length.should > 0
      data.columns.sort.should == SORTED_COLUMNS
    end
  end

end