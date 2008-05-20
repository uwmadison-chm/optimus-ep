# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# This almost completely delegates to TabfileParser

require 'tabfile_parser'

module Eprime
  class Reader
    class ExcelParser < TabfileParser
      def initialize(file, options = {})
        options = options.merge(:skip_lines => 1)
        super(file, options)
      end
    end
  end
end