# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# A runner to take eprime data files, chew them through a pesudo-templater, 
# and produce delicious files for importing into other packages. They'll look
# like:
#
# presented     onset     offset
# stim1         5992      6493
# stim2         7294      7981
#
# This class should handle argument processing, file I/O, and such.
require 'eprime'
require 'eprime_reader'
require 'transformers/timing_extractor'
require 'optparse'

module Eprime
  module Runners
    class TimingExtractorRunner
      attr_accessor :out, :err
      def initialize(*args)
        @out = STDOUT
        @err = STDERR
        @args = args
        @data = nil
        @timing_extractor = nil
        process_arguments!
      end
      
      private
      def  process_arguments!
        build_option_parser
      end
      
      def build_option_parser
        @options = {}
        op = OptionParser.new
        op.banner = "Usage: extract_timings --template TEMPLATE_FILE [OPTIONS] INPUT_FILES"
        op.separator ''
        op.on('-t', '--template=TEMPLATE_FILE', String,
          'A template containing commands describing',
          'how to process these files'
        ) do |template|
          # FILL ME
        end
        op.separator ''
        op.on('--[no-]column-labels',
          'Print column lablels in the first row'
        ) do |label|
          # FILL ME
        end
        op.separator ''
        op.on('-o', '--outfile=OUTFILE',
          "The name of the file to save to. If not",
          "given, print to standard output."
        ) do |filename|
          # FILL ME
        end
        op.separator ''
        op.on('-h', '--help',
          'Print this message'
        ) do |help|
          # FILL ME
        end
      end
      
    end
  end
end