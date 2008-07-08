# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')
require 'transformers/row_filter'
include EprimeTestHelper

describe Eprime::Transformers::RowFilter do
  before :each do
    @edata = mock_edata
  end
  
  it "should allow filtering based on a proc" do
    filter = Eprime::Transformers::RowFilter.new(@edata, lambda { |row| !row['sparse'].to_s.empty? })
    filter.each do |row|
      row['sparse'].to_s.should_not be_empty
    end
  end
  
  it "should filter based on column equal test" do
    filter = Eprime::Transformers::RowFilter.new(@edata, ['run_start', 'equals', 2400])
    filter.to_a.size.should_not == 0
    filter.each do |row|
      row['run_start'].should == '2400'
    end
  end
end