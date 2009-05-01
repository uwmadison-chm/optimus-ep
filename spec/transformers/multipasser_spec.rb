# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')
require 'transformers/multipasser'

include Eprime::Transformers
include EprimeTestHelper

describe Eprime::Transformers::Multipasser do
  before :each do
    @mpass = Multipasser.new(mock_edata)
  end
  
  it "should iterate normally before adding any passes" do
    @mpass.to_a.size.should == mock_edata.size
  end
  
  it "should have all rows when setting a trivial pass" do
    @mpass.add_pass
    @mpass.to_a.size.should == mock_edata.size
  end
  
  it "should have twice as many rows when setting a trivial pass twice" do
    @mpass.add_pass
    @mpass.add_pass
    @mpass.to_a.size.should == (mock_edata.size)*2
  end
  
  describe "with a sort_by" do
    before :each do
      @data = mock_edata
      @mpass = Multipasser.new(@data)
    end
    
    it "should sort normally by an ascending column" do
      @mpass.add_pass("{stim_time}")
      @mpass.to_a.each_index do |i|
        @mpass[i]['stim_time'].should == @data[i]['stim_time']
      end
    end
    
    it "should sort backwards by descending column" do
      @mpass.add_pass("-{stim_time}")
      sd = @data.sort_by { |row| -(row['stim_time'].to_i) }
      @mpass.to_a.each_index do |i|
        @mpass[i]['stim_time'].should == sd[i]['stim_time']
      end
    end

    it "should sort with a computed column" do
      pass = @mpass.add_pass("{neg_stim_time}")
      pass.computed_column "neg_stim_time", "-{stim_time}"
      sd = @data.sort_by { |row| -(row['stim_time'].to_i) }
      @mpass.to_a.each_index do |i|
        @mpass[i]['stim_time'].should == sd[i]['stim_time']
      end
    end
    
    it "should allow multiple passes" do
      pending
      pass = @mpass.add_pass("{fix_time}")
      pass.computed_column "presented_time", "{fix_time}"
      pass.computed_column "presented_name", "'fixation'"
      @mpass.to_a.size.should == @data.size
    end
    
    it "should sort multiple passes together" do
      pending
      #pass = @mpass.add_pass("{fix_time}")
      #pass.computed_column "presented_time", "{fix_time}"
      #pass.computed_column "presented_name", "fixation"
      #pass = @mpass.add_pass("{stim_time}")
      #pass.computed_column "presented_time", "{stim_time}"
      #pass.computed_column "presented_name", "stimulus"
      #@mpass.to_a.size.should == @data.size*2
      #ps = @mpass.to_a.sort_by{|row| row['presented_time'].to_f}
      #@mpass.to_a.each_index do |i|
      #  @mpass[i]['presented_time'].to_s.should == ps[i]['presented_time'].to_s
      #end
    end
    
    it "should work with multiple arguments in constructor" do
      pass = @mpass.add_pass(
        "{fix_time}", 
        lambda {|r| !r['sparse'].to_s.empty?}, 
        [['silly', '{fix_time} - {stim_time}']])
      @mpass.columns.should include('silly')
      @mpass.to_a.size.should == @data.find_all {|r| !r['sparse'].to_s.empty?}.size
    end
  end
  
    
end