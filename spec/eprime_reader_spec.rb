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
  before(:all) do
    File.chmod(0000, UNREADABLE_FILE)
  end
  
  after(:all) do
    File.chmod(0600, UNREADABLE_FILE)
  end
  
  before(:each) do
    @reader = Eprime::Reader.new
  end
  
  it "should raise when file not found" do
    lambda { @reader.load_file('no_such_file') }.should raise_error(Eprime::UnknownTypeError)
  end
  
  it "should raise when file can't be read" do
    lambda { @reader.load_file(UNREADABLE_FILE) }.should raise_error(Eprime::UnknownTypeError)
  end
  
  it "should raise when file is actually a folder" do 
    lambda { @reader.load_file(SAMPLE_DIR) }.should raise_error(Eprime::UnknownTypeError)
  end

  it "shouldn't raise when file is ok" do
    lambda { @reader.load_file(LOG_FILE) }.should_not raise_error
  end
  
  it "should detect log files" do
    @reader.load_file(LOG_FILE)
    @reader.type.should == :log
  end
  
  it "should detect excel csv files" do
    @reader.load_file(EXCEL_FILE)
    @reader.type.should == :excel
  end
  
  it "should detect eprime csv files" do
    @reader.load_file(EPRIME_FILE)
    @reader.type.should == :eprime
  end
  
  it "should raise when filetype is unknown" do
    lambda { @reader.load_file(UNKNOWN_FILE) }.should raise_error(Eprime::UnknownTypeError)
  end
end