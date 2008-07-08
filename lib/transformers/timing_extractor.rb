# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
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

module Eprime
  class TimingExtractor
    def initialize(argv)
      
    end
    
    def extract
    end
  end
end