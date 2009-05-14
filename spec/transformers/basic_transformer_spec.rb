# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# All of the complex behavior is exercised in 

require File.join(File.dirname(__FILE__),'..','spec_helper')
require File.join(File.dirname(__FILE__),'../../lib/eprime')
require File.join('transformers/basic_transformer')
include EprimeTestHelper
include Eprime::Transformers

describe Eprime::Transformers::BasicTransformer do
  before :each do
    @data = mock_edata
    @xf = BasicTransformer.new(@data)
  end
  
  it "should have size" do
    @xf.size.should == @data.size
  end
  
  it "should have columns" do
    @xf.columns.sort.should == @data.columns.sort
  end
  
  it "should allow computing columns" do
    @xf.computed_column 'test', '1'
    @xf.columns.should include('test')
  end
  
  it "should allow copydown columns" do
    @xf.copydown_column 'test', "sparse"
    @xf.columns.should include('test')
  end
  
  it "should allow counter columns" do
    @xf.counter_column 'test'
    @xf.columns.should include('test')
  end
  
  it "should filter rows" do
    @xf.row_filter = lambda {|r| !r['sparse'].to_s.empty? }
    count = @data.find_all { |r| !r['sparse'].to_s.empty? }.size
    @xf.size.should == count
  end
  
  it "should allow adding simple passes without a block" do
    @xf.add_pass(
      '-{stim_time}', 
      lambda {|r| !r['sparse'].to_s.empty?}, 
      [['test', '{stim_time}']]
    )
    df = @data.find_all { |r| !r['sparse'].to_s.empty? }
    @xf.size.should == df.size
  end
  
  it "should allow adding passes without a block" do
    @xf.add_pass('-{stim_time}', lambda {|r| !r['sparse'].to_s.empty?}, [['test', '{stim_time}']])
    df = @data.find_all { |r| !r['sparse'].to_s.empty? }
    @xf.size.should == df.size
    @xf[0]['stim_time'].should == df.reverse[0]['stim_time']
    @xf.columns.should include('test')
  end
  
  it 'should allow adding passes with a block' do
    @xf.add_pass do |p|
      p.sort_expression = '-{stim_time}'
      p.row_filter = lambda { |r| !r['sparse'].to_s.empty?}
      p.computed_column 'test', '{stim_time}'
    end
    df = @data.find_all { |r| !r['sparse'].to_s.empty? }
    @xf.size.should == df.size
    @xf[0]['stim_time'].should == df.reverse[0]['stim_time']
    @xf.columns.should include('test')
  end
end
