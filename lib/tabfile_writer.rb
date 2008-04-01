# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# Just use the standard Ruby CSV processing library; it'll make our lives
# way easier (by handling in-band tabs, etc)
require 'csv'

module Eprime
  
  # Writes an Eprime::Data object as a tab-delmited file -- hopefully exactly
  # like E-DataAid.
  class TabfileWriter
    
    # Create a writer, but don't actually write the output.
    # Valid things in the options hash:
    # :write_top_line => true, if you want to include the filename
    #   (if it's a file output stream) as the first line output
    def initialize(eprime_data, outstream, options = {})
      @eprime = eprime_data
      @outstream = outstream
      @write_top_line = options[:write_top_line]
    end
    
    # Write to the output stream.
    def write
      CSV::Writer.generate(@outstream, "\t") do |tsv|
        if @write_top_line
          name = @outstream.respond_to?(:path) ? File.expand_path(@outstream.path.to_s) : ''
          tsv << [name]
        end
        tsv << @eprime.columns
        @eprime.each do |row|
          tsv << row.values
        end
      end
    end
  end
end