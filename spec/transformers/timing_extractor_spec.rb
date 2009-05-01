# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')
require 'transformers/timing_extractor'
include EprimeTestHelper
include Eprime::Transformers

describe Eprime::Transformers::TimingExtractor do
  before :each do
    @data = mock_edata
    @tx = TimingExtractor.new(@data)
  end
  
  it "should be a BasicTransformer" do
    @tx.should be_a_kind_of(BasicTransformer)
  end
  
  it "should accept extract_stimulus" do
    pending
    #lambda { 
    #  @tx.extract_stimulus('stim_time', 'stim_time', 'stim_time') 
    #}.should_not raise_error
  end
  
  it "should have nothing in extracted_data when no stimuli are extracted" do
    @tx.extracted_data.size.should == 0
  end
  
  it "should return rows when extracting stim_time" do
    pending
    # These results will not be very meaningful
    #@tx.extract_stimulus('stim_time', 'stim_time', 'stim_time') 
    #@tx.extracted_data.size.should == @data.size
  end
  
  it "should accept columns" do
    lambda { @tx.columns }.should_not raise_error
  end
  
  it "should extract from computed columns" do
    pending
    #@tx.computed_column 'foo', "'a'"
    #@tx.columns.should include('foo')
    ##@tx.extract_stimulus('foo', 'foo', 'foo')
    #@tx.extracted_data.size.should == @data.size
  end
  
  it "should honor row filters in stim extraction" do
    pending
    #@tx.extract_stimulus(
    #  'stim_time', 
    #  'stim_time', 
    #  'stim_time',
    #  lambda {|row| !row['sparse'].to_s.empty? }
    #)
    #count = @data.find_all { |r| !r['sparse'].to_s.empty? }.size
    #@tx.extracted_data.size.should == count
  end
  
  describe "(extracting two stimuli)" do
    before :each do
      @data = mock_edata
      @tx = TimingExtractor.new(@data)
      @tx.computed_column('stim_name',"'stim'")
      @tx.computed_column('fix_name', "'fixation'")
      @tx.computed_column('stim_offset', '{stim_time} + 500 - {run_start}')
      @tx.computed_column('fix_offset', '{fix_time}+130-{run_start}')
      #@tx.extract_stimulus('stim_name', 'stim_time', 'stim_time')
      #@tx.extract_stimulus('fix_name', 'fix_time', 'fix_offset')
      @ed = @tx.extracted_data
    end
    
    it "should have columns presented, onset, and offset" do
      pending
      #@ed.columns.should == %w(presented onset offset)
    end
    
    it "should have twice as many rows as @data" do
      pending
      #@ed.size.should == @data.size*2
    end
    
    it "should be ordered by onset" do
      pending
      #ordered = @ed.sort_by { |r| r['onset'].to_f }
      #ordered.each_index do |i|
      #  ordered[i]['onset'].to_s.should == @ed[i]['onset'].to_s
      #end
    end
  end
end