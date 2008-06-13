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
  
  it "should allow setting a computed column" do
    lambda {
      @calc.computed_column NEW_COLUMN, "1"
    }.should_not raise_error
  end
  
  it "should allow setting a copydown column" do
    lambda {
      @calc.copydown_column 'sparse_copy', 'sparse'
    }.should_not raise_error
  end
  
  it "should contain new name when setting computed column" do
    @calc.computed_column NEW_COLUMN, "1"
    @calc.columns.should include(NEW_COLUMN)
  end
  
  it "should contain the new name when setting copydown column" do
    @calc.copydown_column 'sparse_copy', 'sparse'
    @calc.columns.should include('sparse_copy')
  end
  
  it "should increse in column size when setting computed column" do
    s1 = @calc.columns.size
    @calc.computed_column NEW_COLUMN, "1"
    s2 = @calc.columns.size
    s2.should == s1+1
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
  
  it "should raise when adding computed column with existing column name" do
    lambda {
      @calc.computed_column @edata.columns[0], '1'
    }.should raise_error(Eprime::ColumnCalculator::ComputationError)
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

    it "should return data for data columns" do
      @edata[0]['stim_time'].should_not be_nil
      @calc[0].compute('stim_time').should == @edata[0]['stim_time']
    end
    
    it "should compute static columns on single rows" do
      @calc.computed_column "always_1", "1"
      @calc[0].compute("always_1").should == "1"
    end
    
    it "should compute on single rows with some math" do
      @calc.computed_column "test", "(3+2)*4"
      @calc[0].compute("test").should == ((3+2)*4).to_s
    end
    
    it "should allow adding two columns" do 
      @calc.computed_column "always_1", "1"
      @calc.computed_column "test", "(3+2)*4"
      @calc[0].compute("always_1").should == "1"
      @calc[0].compute("test").should == ((3+2)*4).to_s
    end
    
    it "should raise when computing nonexistent column" do
      lambda {
        @calc[0].compute('nonexistent')
      }.should raise_error(IndexError)
    end

    it "should compute constants via indexing" do 
      @calc.computed_column "always_1", "1"
       @calc[0]["always_1"].should == "1"
    end
    
    it "should compute with add, mul, and grouping via indexing" do
      # See calculator_spec.rb for exhaustive testing of the parser
      @calc.computed_column "add_mul", "5*(6+2)"
      @calc.each do |row|
        row["add_mul"].should == (5*(6+2)).to_s
      end
    end
    
    it "should work with multiple computed columns via indexing" do
      @calc.computed_column "always_1", "1"
      @calc.computed_column "add_mul", "5*(6+2)"
      
      @calc.each do |row|
        row["always_1"].should == "1"
        row["add_mul"].should == (5*(6+2)).to_s
      end
    end
  end
  
  describe "(with computed columns)" do
    
    it "should compute based on data columns" do
      @calc.computed_column "stim_time_s", "{stim_time}/1000"
      @calc.each do |row|
        row["stim_time_s"].should == (row["stim_time"].to_f/1000.0).to_s
      end
    end
    
    it "should allow math between two columns" do
      @calc.computed_column "stim_from_run", "{stim_time}-{run_start}"
      @calc.each do |row|
        row['stim_from_run'].should == (row['stim_time'].to_i - row['run_start'].to_i).to_s
      end
    end
    
    it "should allow columns based on other computed columns" do
      @calc.computed_column "stim_from_run", "{stim_time}-{run_start}"
      @calc.computed_column "stim_run_s", "{stim_from_run} / 1000"
      @calc.each do |row|
        row['stim_run_s'].should == ((row['stim_time'].to_f - row['run_start'].to_f)/1000.0).to_s
      end
    end
    
    it "should fail to compute with nonexistent columns" do
      @calc.computed_column "borked", "{stim_time} - {not_there}"
      lambda {
        @calc[0]["borked"]
      }.should raise_error(IndexError)
    end
    
    it "should assume zero when a column has blank values" do
      @calc.computed_column "sparse_plus_0", "{sparse} + 0"
      @calc.each do |row|
        row["sparse"].to_f.should == row["sparse_plus_0"].to_f
      end
    end
    
    it "should detect loops in column computation" do
      @calc.computed_column "loop1", "{stim_time} - {run_start} - {loop3}"
      @calc.computed_column "loop2", "{loop1}"
      @calc.computed_column "loop3", "{loop2}"
      @calc.computed_column "loop4", "{loop3}"
      lambda {
        @calc[0]['loop4']
      }.should raise_error(Eprime::ColumnCalculator::ComputationError)
    end
    
    it "should compute columns when there are two paths to a node" do
      @calc.computed_column "c1", "{stim_time} - {run_start}"
      @calc.computed_column "c2", "{c1}"
      @calc.computed_column "c3", "{c1} - {c2}"
      lambda {
        @calc[0]["c3"]
      }.should_not raise_error
    end
    
  end
  
  describe "(with copydown columns)" do
    before :each do
      @calc.copydown_column 'sparse_copy', 'sparse'
    end
    
    it "should work" do
      last_val = ''
      @calc.each do |row|
        if !row['sparse'].to_s.empty?
          last_val = row['sparse'].to_s
        end
        row['sparse_copy'].should == last_val
      end
    end
  end
  
  describe "(with counter columns)" do
    it "should count up with no options" do
      @calc.counter_column "count_up"
      i = 0;
      @calc.each do |row|
        i += 1
        row["count_up"].should == i
      end
    end
  
    it "should count from 1 when :start_value is set" do
      @calc.counter_column "count_up", :start_value => 1
      i = 1
      @calc.each do |row|
        i += 1
        row["count_up"].should == i
      end
    end
    
    it "should count down when :count_by is -1" do
      @calc.counter_column "count_down", :count_by => -1
      i = 0
      @calc.each do |row|
        i -= 1
        row['count_down'].should == i
      end
    end
    
    it "should count by a proc when specified" do
      @calc.counter_column "count_succ", :count_by => lambda {|val| val.succ}
      i = 0
      @calc.each do |row|
        i = i.succ
        row["count_succ"].should == i
      end
    end
    
    it "should count by a symbol when specified" do
      @calc.counter_column "count_succ", :count_by => :succ
      i = 0
      @calc.each do |row|
        i = i.succ
        row['count_succ'].should == i
      end
    end
    
    it "count by a string when specified" do
      @calc.counter_column "count_succ", :count_by => 'succ'
      i = 0
      @calc.each do |row|
        i = i.succ
        row['count_succ'].should == i
      end
    end
    
    it "should count only when :count_when is true" do
      @calc.counter_column "count_on_sparse", :count_when => lambda {|row| !row['sparse'].to_s.empty? }
      
      i = 0
      @calc.each do |row|
        i += 1 if !row['sparse'].to_s.empty?
        row['count_on_sparse'].should == i
      end
    end
    
    it "should reset when :reset_when is true" do
      @calc.counter_column "reset_on_sparse", :reset_when => lambda {|row| !row['sparse'].to_s.empty? }
      i = 0
      @calc.each do |row|
        i = 0 if !row['sparse'].to_s.empty?
        i += 1
        row['reset_on_sparse'].should == i
      end
    end
  end
end

describe Eprime::ColumnCalculator::Expression do
  before :each do
    @expr_str = "({stim_time}-{run_start}) / 1000"
    @expr = Eprime::ColumnCalculator::Expression.new(@expr_str)
  end
  
  it "should find two columns" do
    @expr.columns.size.should == 2
  end
  
  it "should split into stim_time and run_start" do
    @expr.columns.sort.should == %w(stim_time run_start).sort
  end
  
  it "should not allow changing columns" do
    lambda {
      @expr.columns << 'wakka'
    }.should raise_error(TypeError)
  end
  
  it "should convert to a string" do
    @expr.to_s.should == @expr_str
  end
end

