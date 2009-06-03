# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# This almost completely delegates to TabfileParser

require 'tabfile_parser'

module Optimus
  class Reader
    class OptimustabParser < TabfileParser
      def initialize(file, options = {})
        options = options.merge(:skip_lines => 3)
        super(file, options)
      end
      
      def self.can_parse?(lines)
        divided = lines.map { |l| l.strip.split("\t") }
        return (
          divided[0].size >= 3 and 
          divided[0].size == divided[1].size and
          divided[0][0] == 'STRING' and
          divided[1][0] == 'EXPNAME'
        )
      end
    end
  end
end