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
  
  after(:each) do
  end
  
  it "should detect log files" do
    File.open(LOG_FILE, 'r') do |file|
      @reader.read_input(file)
      @reader.type.should == :log
    end
  end
  
  it "should detect excel csv files" do
    File.open(EXCEL_FILE) do |file|
      @reader.read_input(file)
      @reader.type.should == :excel
    end
  end
  
  it "should detect eprime csv files" do
    File.open(EPRIME_FILE) do |file|
      @reader.read_input(file)
      @reader.type.should == :eprime
    end
  end
  
  it "should raise when filetype is unknown" do
    File.open(UNKNOWN_FILE) do |file|
      lambda { @reader.read_input(file) }.should raise_error(Eprime::UnknownTypeError)
    end
  end
end