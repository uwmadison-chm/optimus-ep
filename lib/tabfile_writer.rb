# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# Just use the standard Ruby CSV processing library; it'll make our lives
# way easier (by handling in-band tabs, etc)
require 'csv'

module Optimus
  
  # Writes an Optimus::Data object as a tab-delmited file -- hopefully exactly
  # like E-DataAid.
  class TabfileWriter
    
    # Create a writer, but don't actually write the output.
    # Valid things in the options hash:
    # :write_top_line => true, if you want to include the filename
    #   (if it's a file output stream) as the first line output
    def initialize(optimus_data, outstream, options = {})
      standard_options = {
        :write_top_line => false,
        :columns => nil,
        :column_labels => true
      }
      good_opts = standard_options.merge(options)
      @optimus = optimus_data
      @outstream = outstream
      @write_top_line = good_opts[:write_top_line]
      @columns = good_opts[:columns] || @optimus.columns
      @column_labels = good_opts[:column_labels]
    end
    
    # Write to the output stream.
    def write
      tsv = nil
      begin
        tsv = CSV::Writer.create(@outstream, col_sep="\t")
      rescue
        tsv = CSV.new(@outstream, {:col_sep => "\t"})
      end
      if @write_top_line
        name = @outstream.respond_to?(:path) ? File.expand_path(@outstream.path.to_s) : ''
        tsv << [name]
      end
      if @column_labels
        tsv << @columns
      end
      @optimus.each do |row|
        vals = @columns.map { |col_name| row[col_name] }
        tsv << vals
      end
    end
  end
end