# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'spec_helper')
require File.join(File.dirname(__FILE__), '../lib/eprime')
require 'stringio'

include EprimeTestHelper

E_ROWS = 3
E_COLS = 4

describe "Eprime::TabfileWriter" do
  
  before :each do
    @eprime_data = mock_eprime(E_COLS, E_ROWS)
    @out_s = StringIO.new
  end
  
  it "should succeed at writing" do
    writer = Eprime::TabfileWriter.new(@eprime_data, @out_s)
    writer.write
  end
  
  describe "without filename line" do
    before :each do
      @writer = Eprime::TabfileWriter.new(@eprime_data, @out_s)
      @writer.write
      @out_s.rewind
    end
    
    it "should write out #{E_ROWS+1} lines" do
      @out_s.readlines.size.should == E_ROWS+1
    end
    
    it "should write a first line containing #{E_COLS} tab-separated elements" do
      @out_s.gets.split("\t").size.should == E_COLS
    end
    
    it "should have blank spaces for nil value in last line" do
      @out_s.readlines.last.split("\t").should include('')
    end
  end
  
  describe "with filename line" do
    before :each do
      def @out_s.path # Redefine this so we can test the first line trick
        'spec_test'
      end
      @writer = Eprime::TabfileWriter.new(@eprime_data, @out_s, :write_top_line => true)
      @writer.write
      @out_s.rewind
    end
    
    it "should write out #{E_ROWS+2} lines" do
      @out_s.readlines.size.should == E_ROWS+2
    end
    
    it "should have the file path with spec_test as the first line" do
      @out_s.gets.strip.should == File.expand_path('spec_test')
    end
    
  end
  
  describe "with good output columns specified" do
    before :each do
      @writer = Eprime::TabfileWriter.new(@eprime_data, @out_s, :columns => ['col_2'])
      @writer.write
      @out_s.rewind
    end
    
    it "should include only one column" do
      lines = @out_s.readlines
      lines[0].split("\t").size.should == 1
      lines[1].split("\t").size.should == 1
      lines[1].split("\t")[0].strip.should == "c_2_r_1"
    end
  end
  
  describe "with nonexistent output column specified" do

    it "should raise an error when specifying a nonexistent column" do
      @writer = Eprime::TabfileWriter.new(@eprime_data, @out_s, :columns => ['KITTEH'])
      lambda { @writer.write }.should raise_error(IndexError)
    end
  end
end