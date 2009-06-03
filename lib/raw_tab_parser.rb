# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# This almost completely delegates to TabfileParser
# It differs from OptimustabParser only in that it doesn't skip any lines.

require 'tabfile_parser'

module Optimus
  class Reader
    class RawTabParser < TabfileParser
      def initialize(file, options = {})
        options = options.merge(:skip_lines => 0)
        super(file, options)
      end
      
      def self.can_parse?(lines)
        ary = lines.map { |l| l.strip.split("\t") }
        ary[0].size > 1 and ary.all? {|e| e.size == ary[0].size}
      end
    end
  end
end