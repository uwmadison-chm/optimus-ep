# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison
#
# This class handles the creation of files that look, essentially, like:
# presented     onset_time      offset_time
# stim1         2477            4918
# ...
#
# In other words, tab-delimited files containing the time a stimulus was
# presented, and the time the presentation stopped.
#
# In an experiment, this will take, as an argument, a template written in ruby
# that will be eval'd in the context of this instance -- that will contain
# the guts of the logic to extract stimuli.
require 'transformers/basic_transformer'

module Optimus
  module Transformers
    class TimingExtractor < BasicTransformer
      def initialize(data)
        super(data)
        @stim_schemas = []
        @extracted_data = nil
      end
      
      def extract_stimulus(
        name_column,
        onset_column,
        offset_column,
        row_filter = (lambda { |r| true }) 
      )
        @stim_schemas << {
          'name_column' => name_column,
          'onset_column' => onset_column,
          'offset_column' => offset_column,
          'row_filter' => row_filter
        }
        @extracted_data = nil
      end
      
      def extracted_data
        extract!
        return @extracted_data
      end
      
      private
      def extract_reset!
        @extracted_data = nil
      end
      
      def extract!
        return if @extracted_data
        @extracted_data = Optimus::Data.new
        @stim_schemas.each do |ss|
          matches = processed.find_all(&ss['row_filter'])
          matches.each do |row|
            nr = @extracted_data.add_row
            nr['presented'] = row[ss['name_column']]
            nr['onset'] = row[ss['onset_column']]
            nr['offset'] = row[ss['offset_column']]
            nr.sort_value = nr['onset'].to_f
          end
        end
        @extracted_data.sort!
      end
    end
  end
end