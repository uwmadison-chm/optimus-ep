# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/optimus')
require 'runners/generic_runner'
include OptimusTestHelper

describe Optimus::Runners::GenericRunner do
  before :each do
    @txr = Optimus::Runners::GenericRunner.new(Optimus::Transformers::BasicTransformer)
  end
  
  it "should start with stdout in @out" do
    @txr.out.should == STDOUT
  end
  
  it "should start with stderr in @err" do
    @txr.err.should == STDERR
  end
end