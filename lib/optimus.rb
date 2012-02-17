# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# Add our lib to the search path
$: << File.expand_path(File.join(File.dirname(__FILE__), "..", "lib"))

require 'optimus_data'
require 'version'
require 'tabfile_writer'
require 'optimus_reader'

module Optimus

  class Error < RuntimeError; end

  # Raised whenever an input file's type can't be detemined by Optimus::Reader
  class UnknownTypeError < Error; end
  
  # Raised whenever an input file seems to be damaged
  class DamagedFileError < Error; end
  
  class ParseError < Error; end
  
  # Raised when a parse fails due to loops
  class EvaluationLoopError < ParseError; end
  
  class DuplicateColumnError < Error; end
  
end