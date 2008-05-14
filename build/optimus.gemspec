# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require 'rubygems' 

Gem::Specification.new do |s|
  s.name = 'optimus'
  s.version = '0.3'
  s.platform = Gem::Platform::RUBY
  s.author = "Nathan Vack"
  s.email = "njvack@wisc.edu"
  s.summary = "A collection of utilities to manage EPrime files"
  s.homepage = "http://code.google.com/p/optimus-ep/"
  s.executables = ["eprime2tabfile"]

  s.files = %w(Rakefile) +
  Dir.glob("{misc,bin,spec,examples}/**/*") +
  Dir.glob("{lib}/**/*.rb")
  s.require_path = "lib"
  s.bindir = "bin"
  s.has_rdoc = false
end
