# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')

require 'transformers/column_calculator'

include EprimeTestHelper

NEW_COLUMN = 'NEW_COLUMN'

describe Eprime::Transformers::ColumnCalculator do
  before :each do
    @edata = mock_edata
    @pc = Eprime::Transformers::ColumnCalculator.new
    @pc.data = @edata
  end
  
  it "should allow adding a computed column" do
    lambda {
      @pc.computed_column NEW_COLUMN, "1+1"
    }.should_not raise_error
  end
  
  it "should be enumerable" do
    @pc.should be_a_kind_of(Enumerable)
  end
  
  it "should have columns" do
    @pc.columns.sort.should == @edata.columns.sort
  end
  
  it "should add new columns" do
    @pc.computed_column NEW_COLUMN, "1"
    @pc.columns.should include(NEW_COLUMN)
  end
  
  it "should raise an error when adding bad columns" do
    lambda {
      @pc.computed_column NEW_COLUMN, "FIAL"
    }.should raise_error(RParsec::ParserException)
  end
  
  it "should bring forth existing data" do
    col = @edata.columns[0]
    @pc.map {|row| row[col]}.should == @edata.map {|row| row[col]}
  end
  
  it "should return values for columns based on literals" do
    @pc.computed_column NEW_COLUMN, "1"
    @pc.each do |row|
      row[NEW_COLUMN].should == 1
    end
  end
  
  it "should return values for columns based on lambdas" do
    @pc.computed_column NEW_COLUMN, lambda {|row| row['stim_time'] }
    @pc.computed_column "NEW_COL2", lambda {|row| 1}
    @pc.each do |row|
      row[NEW_COLUMN].should == row['stim_time']
      row["NEW_COL2"].should == 1
    end
  end
  
  it "should return computed columns based on literal columns" do
    @pc.computed_column NEW_COLUMN, "{stim_time}"
    @pc.each do |row|
      row[NEW_COLUMN].should == row['stim_time'].to_f
    end
  end
  
  it "should return computed columns based on other computed columns" do
    @pc.computed_column "FOO2", "{#{NEW_COLUMN}}"
    @pc.computed_column NEW_COLUMN, "{stim_time}"
    @pc.each do |row|
      row["FOO2"].should == row['stim_time'].to_f
    end
  end
  
  it "should raise a loop error when detecting a loop" do
    @pc.computed_column "nc1", "{nc2}"
    @pc.computed_column "nc2", "{nc1}"
    lambda {
      @pc[0]
    }.should raise_error(Eprime::EvaluationLoopError)
  end
  
  it "should pass a somewhat arbitrary test" do
    @pc.computed_column "result", "({stim_time} - {run_start})+ 100 / 2"
    @pc.each do |row|
      row['result'].should == (
        (row['stim_time'].to_f - row['run_start'].to_f)+100/2)
    end
  end
  
  it "should not allow adding a column with an existing name" do
    lambda {
      @pc.computed_column "stim_time", "1"
    }.should raise_error(Eprime::DuplicateColumnError)
  end
  
  describe "with reset logic" do
    it "should allow setting a column with reset_when logic" do
      lambda {
        @pc.computed_column NEW_COLUMN, "{stim_time}", :reset_when => "1"
      }.should_not raise_error
    end
    
    it "should reset only when condition passes" do
      @pc.computed_column NEW_COLUMN, "{stim_time}", 
        :reset_when => "{sparse}"
      val = ''
      @pc.each do |row|
        val = row['stim_time'] if row['sparse'].to_s != ''
        row[NEW_COLUMN].to_f.should == val.to_f
      end
    end
    
    it "should reset with an always true condition" do
      @pc.computed_column NEW_COLUMN, "{stim_time}", :reset_when => "1"
      @pc.each do |row|
        row[NEW_COLUMN].to_f.should == row['stim_time'].to_f
      end
    end
    
    it "should never update when false condition" do
      @pc.computed_column NEW_COLUMN, "{stim_time}", :reset_when => "''"
      @pc.each do |row|
        row[NEW_COLUMN].should be_nil
      end
    end
    
    it "should accept :once as a reset condition" do
      @pc.computed_column NEW_COLUMN, "{stim_time}", :reset_when => :once
      val = @pc[0]['stim_time']
      @pc.each do |row|
        row[NEW_COLUMN].to_f.should == val.to_f
      end
    end
  end
  
  describe "with counting logic" do
    it "should count" do
      init = 0
      @pc.computed_column NEW_COLUMN, init, :count_when => "1", 
        :count_by => :next, :reset_when => :once
      @pc.each do |row|
        init += 1
        row[NEW_COLUMN].to_f.should == init.to_f
      end
    end
    
    it "should count sometimes" do
      init= 0
      @pc.computed_column NEW_COLUMN, init, :count_when => "{sparse}",
        :reset_when => :once, :count_by => :next
      
      @pc.each do |row|
        if row['sparse'].to_s != ''
          init += 1
        end
        
        row[NEW_COLUMN].to_f.should == init.to_f
      end
    end
    
    it "should reset sometimes" do
      init = 0
      @pc.computed_column NEW_COLUMN, init, :count_when => "1", 
        :count_by => :next, :reset_when => "{sparse}"
      
      @pc.each do |row|
        
      end
    end
  end
end