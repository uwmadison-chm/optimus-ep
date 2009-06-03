# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/optimus')
include OptimusTestHelper



describe Optimus::Reader::LogfileParser do
  describe "parsing a good file" do
    before :each do
      @file = File.open(LOG_FILE, 'r')
      @reader = Optimus::Reader::LogfileParser.new(@file)
      @reader.make_frames!
    end
  
    it "should create six frames from the example file" do
      @reader.frames.size.should == 6
    end
  
    it "should have data in every frame" do
      @reader.frames.detect{ |c| c.keys.size == 0}.should be_nil
    end
  
    it "should have a level 2 frame at the start" do
      @reader.frames.first.level.should == 2
    end
  
    it "should have a level 1 frame at the end" do
      @reader.frames.last.level.should == 1
    end
  
    it "should have a known BlockTitle key in first frame" do
      @reader.frames.first["BlockTitle"].should_not be_nil
    end
  
    it "should not have a known Gibberish key in first frame" do
      @reader.frames.first["Gibberish"].should be_nil
    end
  
    it "should have a known RandomSeed key in last frame" do
      @reader.frames.last["RandomSeed"].should_not be_nil
    end
  
    it "should not have a known StartR.OnsetTime key in last frame" do
      @reader.frames.last["StartR.OnsetTime"].should be_nil
    end
    
    it "should read levels from the header" do
      @reader.levels.should include("Session")
    end
    
    it "should have four leaves" do
      @reader.leaf_frames.length.should == 4
    end
  
    it "should have a parent in the first frame" do
      @reader.frames.first.parent.should_not be_nil
    end
    
    describe "making optimus data" do
      before :each do
        @optimus = @reader.to_optimus
      end
    
      it "should generate four rows from the example file" do
        @optimus.length.should == 4
      end
      
      it "should follow the column order in the example file" do
        @optimus.columns[0].should == "ExperimentName"
        @optimus.columns[1].should == "SessionDate"
      end
      
      it "should ignore extra colons in input data" do
        @optimus.first['SessionTime'].should == '11:11:11'
      end
    
      it "should append level name to ambiguous columns" do
        @optimus.columns.should include("CarriedVal[Session]")
      end
      
      it "should not include ambiguous columns without level name" do
        @optimus.columns.should_not include("CarriedVal")
      end
      
      it "should include columns from level 2 and level 1 frames" do
        @optimus.columns.should include("RandomSeed")
        @optimus.columns.should include("BlockTitle")
      end
      
      it "should rename Experiment to ExperimentName" do
        @optimus.columns.should include("ExperimentName")
        @optimus.columns.should_not include("Experiment")
      end
    
      it "should compute task counters" do
        @optimus.first["Block"].should == 1
        @optimus.last["Block"].should == 3
        @optimus.last["Trial"].should == 2
      end
    
      it "should have a counter column" do
        @optimus.columns.should include("Trial")
      end
    end
  end
  
  describe "with sorted columns" do
    before :each do
      @file = File.open(LOG_FILE, 'r')
      @reader = Optimus::Reader::LogfileParser.new(@file, :columns => STD_COLUMNS)
      @reader.make_frames!
      @optimus = @reader.to_optimus
    end
    
    after :each do
      @file.close
    end
    
    it "should have ExperimentName first" do
      @optimus.columns.first.should == "ExperimentName"
    end
    
    it "should have four rows" do
      @optimus.length.should == 4
    end
    
    
  end
  
  describe "parsing bad files" do
    before :each do
      @file = File.open(CORRUPT_LOG_FILE, 'r')
      @reader = Optimus::Reader::LogfileParser.new(@file)
    end
    after :each do
      @file.close
    end
    
    it "should throw an error when the last frame is not closed" do
      lambda {@reader.make_frames!}.
        should raise_error(Optimus::DamagedFileError)
    end
    
  end
  
end

describe Optimus::Reader::LogfileParser::ColumnList do
  before :each do
    @cklass = Optimus::Reader::LogfileParser::Column
    @levels = ['', 'Foo', 'Bar']
    @list = Optimus::Reader::LogfileParser::ColumnList.new(@levels)
  end
  
  it "should raise error when storing index 0" do
    lambda {
      @list.store(@cklass.new('test', 0))
    }.should raise_error(IndexError)
  end
  
  it "should raise error when storing out of bounds" do
    lambda {
      @list.store(@cklass.new('test', @levels.length))
    }.should raise_error(IndexError)
  end
    
  it "should record and return names" do
    @list.store(@cklass.new('test', 1))
    @list.names.should == ['test']
  end
  
  it "should not re-add repeated name at same level" do
    @list.store(@cklass.new('test', 1))
    @list.store(@cklass.new('test', 1))
    @list.names.should == ['test']
  end

  it "should record unique column names at different levels" do
    @list.store(@cklass.new('test', 1))
    @list.store(@cklass.new('another_test', 2))
    @list.names.should == ['test', 'another_test']
  end
  
  it "should add level names to repeated column names at different levels" do
    @list.store(@cklass.new('test', 1))
    @list.store(@cklass.new('test', 2))
    @list.names.should == ['test[Foo]', 'test[Bar]']
  end
  
  it "should return paired columns with names" do
    col = @cklass.new('test', 1)
    @list.store(col)
    
    @list.names_with_cols.should == [
      ['test', col]
    ]
  end
  
end