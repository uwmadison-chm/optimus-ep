# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# Require the entire package
require File.dirname(__FILE__)+'/eprime_reader'
require File.dirname(__FILE__)+'/log_file_parser'
require File.dirname(__FILE__)+'/eprime_data'
require File.dirname(__FILE__)+'/tabfile_parser'
require File.dirname(__FILE__)+'/tabfile_writer'

module Eprime

  # Raised whenever an input file's type can't be detemined by Eprime::Reader
  class UnknownTypeError < Exception; end
  
  # Raised whenever an input file seems to be damaged
  class DamagedFileError < Exception; end
  
end