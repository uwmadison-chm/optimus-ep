# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
# 
# This execrises the main command-line runner system.

require File.join(File.dirname(__FILE__),'../../spec_helper')
require File.join(File.dirname(__FILE__), '../../../lib/optimus')
include OptimusTestHelper

require 'runners/yaml_template/runner'

include Optimus::Runners::YamlTemplate

describe Runner do
  it "is pending"
end