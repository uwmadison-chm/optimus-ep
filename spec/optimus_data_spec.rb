# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/optimus')
include OptimusTestHelper

INITIAL_COLUMNS = %w(col1 col2 col3 col4)
NEW_COL_1 = "new_column_1"
NEW_COL_2 = "new_column_2"

shared_examples_for "empty Optimus::Data" do
  it "should have no rows" do
    @data.length.should == 0
  end
  
  it "should allow new rows" do
    @data.add_row.should_not be_nil
  end
end

shared_examples_for "Optimus::Data with one row" do
  it "should be row-indexable" do
    @data[0].should === @row # Test for identicality
  end

  it "should store column values by name" do
    @row[INITIAL_COLUMNS[0]] = "kitten"
    @row[INITIAL_COLUMNS[0]].should == "kitten"
  end

  it "should reset column values" do
    @row[INITIAL_COLUMNS[0]] = "kitten"
    @row[INITIAL_COLUMNS[0]] = "bitten"
    @row[INITIAL_COLUMNS[0]].should == "bitten"
  end

  it "should allow setting column values by numeric index" do
    @row[INITIAL_COLUMNS[0]] = "kitten"
    index = @data.find_column_index(INITIAL_COLUMNS[0])
    @row[index] = "bitten"
    @row[index].should == "bitten"
  end
  
  it "should not lose columns when duplicating" do
    @data.columns.should == @data.dup.columns
  end

  it "should raise when setting out-of-bound column value" do
    lambda {
      @row[@data.columns.length] = "kitten"
    }.should raise_error(IndexError)
  end

  it "should raise IndexError when querying for nonexistent column names" do
    lambda {
      @row[NEW_COL_1]
    }.should raise_error(IndexError)
  end

  it "should raise IndexError when querying for nonexistent column index" do
    lambda {
      @row[@data.columns.length]
    }.should raise_error(IndexError)
  end

  it "should return nil when querying columns set in other rows" do
    @row[INITIAL_COLUMNS[0]] = "kitteh"
    new_row = @data.add_row
    new_row[INITIAL_COLUMNS[0]].should be_nil
  end
  
  it "should get values" do
    @row[INITIAL_COLUMNS[0]] = "kitten"
    @row.values.should include("kitten")
  end
end

describe Optimus::Data do
  describe "without initial columns" do
    before :each do
      @data = Optimus::Data.new
      @d2 = mock_optimus(2,3)
      @d3 = mock_optimus(2,4)
    end
    
    it "should have return an Optimus::Data object on merge" do
      @data.merge(@d2).should be_an_instance_of(Optimus::Data)
    end

    describe "(empty)" do
      it_should_behave_like "empty Optimus::Data"
  
      it "should have no columns at creation" do
        @data.columns.length.should == 0
      end

      it "should add rows on merge" do
        d = @data.merge(@d2)
        d.size.should == (@data.size + @d2.size)
      end
      
      it "should add rows to the original object on merge!" do
        lambda {
          @data.merge!(@d2, @d3)
        }.should change(@data, :size).by(@d2.size + @d3.size)
      end
      
      it "should not change the original object's size on merge" do
        lambda {
          @data.merge(@d2, @d3)
        }.should_not change(@data, :size)
      end
    end
  
    describe "(with one row)" do
      before :each do
        @row = @data.add_row
      end

      it "should should add rows on merge" do
        d = @data.merge(@d2, @d3)
        d.size.should == (@data.size + @d2.size + @d3.size)
      end
  
      it_should_behave_like "Optimus::Data with one row"
  
      it "should add a column when setting a value in row" do
        @row[NEW_COL_1] = "test_value"
        @data.columns.should satisfy do |c|
          c.include?(NEW_COL_1)
        end
      end

      it "should not add the same column name twice" do
        @row[NEW_COL_1] = "value1"
        lambda {
          @row[NEW_COL_1] = "value2"
        }.should_not change(@data.columns, :length)
      end

      it "should add a second column" do
        @row[NEW_COL_1] = "value"
        lambda {
          @row[NEW_COL_2] = "value"
        }.should change(@data.columns, :length)
      end
      
    end
  end
end

describe "Optimus::Data with initial columns" do
  describe "without setting ignore" do
    before :each do
      @data = Optimus::Data.new(INITIAL_COLUMNS)
    end
  
    describe "(empty)" do
      it_should_behave_like "empty Optimus::Data"
    
      it "should have the same number of columns as INITIAL_COLUMNS" do
        @data.columns.length.should == INITIAL_COLUMNS.length
      end
    
    end
  
    describe "(with one row)" do
      it_should_behave_like "Optimus::Data with one row"
    
      before :each do
        @row = @data.add_row
      end
    
      it "should raise a warning when adding a new column" do
        lambda {
          @row[NEW_COL_1] = "kitteh"
        }.should raise_error(Optimus::ColumnAddedWarning)
      end
    
    end
  end
  
  describe "with ignore set" do
    before :each do
      @data = Optimus::Data.new(INITIAL_COLUMNS, :ignore_warnings => true)
    end
    
    it "should not raise a warning when adding a new column" do
      row = @data.add_row
      lambda {
        row[NEW_COL_1] = "kitteh"
      }.should_not raise_error
    end
    
    it "should add new columns" do
      row = @data.add_row
      row[NEW_COL_1] = "kitteh"
      row[NEW_COL_1].should == "kitteh"
    end
  end
end