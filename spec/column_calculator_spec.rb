# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/eprime')

require 'column_calculator'

include EprimeTestHelper

NEW_COLUMN = 'NEW_COLUMN'

shared_examples_for "Eprime::ColumnCalculator with edata" do
  it "should have the proper size" do
    @calc.size.should == @edata.size
  end
  
  it "should allow accessing rows" do
    @calc[0].should be_an_instance_of(Eprime::ColumnCalculator::Row)
  end
  
  it "should return data" do
    @calc[0]['stim_time'].should == @edata[0]['stim_time']
  end
  
  it "should compute column indexes for data column names" do
    @calc.column_index('stim_time').should == 0
    @calc.column_index('run_start').should == 1
  end
  
  it "should find column indexes for data columns" do
    @calc.column_index(0).should == 0
    @calc.column_index(1).should == 1
  end
  
  it "should return nil when searching for out-of-bound named indexes" do
    @calc.column_index('not_present').should be_nil
  end
  
  it "should return nil when searching for out-of-bound numeric indexes" do
    @calc.column_index(@calc.columns.size).should be_nil
  end

  it "should allow setting a column" do
    lambda {
      @calc.computed_column NEW_COLUMN, "1"
    }.should_not raise_error
  end
  
  it "should contain new name when setting computed column" do
    @calc.computed_column NEW_COLUMN, "1"
    @calc.columns.should include(NEW_COLUMN)
  end
  
  it "should increse in column size when setting computed column" do
    lambda {
      @calc.computed_column NEW_COLUMN, "1"
    }.should change(@calc.columns, :size).by(1)
  end
  
  it "should compute the proper column index for computed columns" do
    prev_max_index = @calc.columns.size-1
    @calc.computed_column NEW_COLUMN, "1"
    @calc.column_index(NEW_COLUMN).should == prev_max_index+1
  end
  
  it "should find numeric indexes for computed columns" do
    get_index = @calc.columns.size
    @calc.computed_column NEW_COLUMN, '1'
    @calc.column_index(get_index).should == get_index
  end
  
  it "should allow named indexing for computed columns" do
    @calc.computed_column NEW_COLUMN, "1"
    lambda {
      @calc[0][NEW_COLUMN]
    }.should_not raise_error
  end
  
  it "should allow numeric indexing for computed columns" do
    @calc.computed_column NEW_COLUMN, "1"
    lambda {
      @calc[0][NEW_COLUMN]
    }.should_not raise_error
  end
  
  it "should raise when name-indexing nonexistent column" do
    lambda {
      @calc[0][NEW_COLUMN]
    }.should raise_error(IndexError)
  end
  
  it "should raise when numerically indexing nonexistent column" do
    lambda {
      @calc[0][@calc.columns.size]
    }.should raise_error(IndexError)
  end
  
end

describe Eprime::ColumnCalculator do
  before :each do
    @edata = mock_edata
    @calc = Eprime::ColumnCalculator.new
    @calc.data = @edata
  end
  
  describe "(with no computed columns)" do
    it "should should have only static columns" do
      @calc.columns.should == @edata.columns
    end
    
    it_should_behave_like "Eprime::ColumnCalculator with edata"
  end
  
  describe "(statically computing columns)" do
    
    it_should_behave_like "Eprime::ColumnCalculator with edata"
    
    
    it "should compute constants" do 
      @calc.computed_column "always_1", "1" 
      @calc.all? { |row|
        row["always_1"] == "1" 
      }.should be_true 
    end
    
    it "should compute with add, mul, and grouping" do
      # Rely on calculator_spec for exhaustive testing of the parser
      @calc.computed_column "add_mul", "5*(6+2)"
      @calc.all? {|row|
        row["add_mul"] == (5*(6+2)).to_s
      }.should be_true
    end
  end
  
end