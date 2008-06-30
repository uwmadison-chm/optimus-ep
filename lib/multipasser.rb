# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

# This class provides the ability for a dataset to be 'exploded' into more
# rows than originally existed. For example, you might have:
# fixation_time stim_time
# 10            30
# 100           130
#
# And want to change it to:
# presented_object  time
# fixation          10
# stimulus          30
# fixation          100
# stimulus          130

module Eprime
  class Multipasser
    
  end
end