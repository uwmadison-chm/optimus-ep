# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

module EprimeTestHelper
  unless constants.include?('SAMPLE_DIR')
    SAMPLE_DIR = File.join(File.dirname(__FILE__), 'samples')
    LOG_FILE = File.join(SAMPLE_DIR, 'optimus_log.txt')
    EXCEL_FILE = File.join(SAMPLE_DIR, 'excel_tsv.txt')
    BAD_EXCEL_FILE = File.join(SAMPLE_DIR, 'bad_excel_tsv.txt')
    EPRIME_FILE = File.join(SAMPLE_DIR, 'eprime_tsv.txt')
    UNKNOWN_FILE = File.join(SAMPLE_DIR, 'unknown_type.txt')
    UNREADABLE_FILE = File.join(SAMPLE_DIR, 'unreadable_file')
    CORRUPT_LOG_FILE = File.join(SAMPLE_DIR, 'corrupt_log_file.txt')
    
    
    STD_COLUMNS = ["ExperimentName", "Subject", "Session", "RFP.StartTime", "BlockTitle", "PeriodA", "CarriedVal[Session]", "BlockList", "Trial", 
    "NameOfPeriodList", "NumPeriods", "PeriodB", "Procedure[Block]", "Block", "Group", 
    "CarriedVal[Block]", "BlockList.Sample", "SessionTime", "Clock.Scale", "BlockList.Cycle", 
    "Stim1.OnsetTime", "CarriedVal[Trial]", "Display.RefreshRate", "Running[Block]", 
    "StartDelay", "Stim1.OffsetTime", "Running[Trial]", "ScanStartTime", 
    "Periods", "TypeA", "BlockElapsed", "RFP.LastPulseTime", "BlockTime", "Procedure[Trial]", 
    "SessionDate", "TypeB", "StartTime", "RandomSeed"]
    
    SORTED_COLUMNS = STD_COLUMNS.sort
    
    SHORT_COLUMNS = ["ExperimentName", "Subject"]

    CONST_EXPRS = {
      :const            => ["1",        lambda { 1 }],
      :add              => ["1+3",      lambda { 1+3 }],
      :mul              => ["2*4",      lambda { 2*4 }],
      :add_neg          => ["4 + -5",   lambda { 4 + -5 }],
      :add_mul_group    => ["4*(3+2)",  lambda { 4*(3+2) }],
      :fdiv             => ["9/2.0",    lambda { 9/2.0 }],
      :fmul             => ["0.44*10",  lambda { 0.44*10 }],
      :mod              => ["10 % 4",   lambda { 10 % 4}]
    }
    
    COMP_EXPRS = {
      'stim_offset'     => '{stim_time} - {run_start}',
      'stim_offset_s'   => '{stim_offset}/1000'
    }

  end
  
  
  def mock_eprime(col_count, row_count)
    data = Eprime::Data.new()
    1.upto(row_count) do |rownum|
      row = data.add_row
      1.upto(col_count) do |colnum|
        unless (rownum == row_count and colnum > 1)
          # Leave some blanks in the last row
          row["col_#{colnum}"] = "c_#{colnum}_r_#{rownum}"
        end
      end
    end
    return data
  end
  
  def mock_edata
    data = Eprime::Data.new()
    row = data.add_row
    row['stim_time'] = '3188'
    row['run_start'] = '2400'
    row = data.add_row
    row['stim_time'] = '4515'
    row['run_start'] = '2400'
    row['sparse'] = '20'
    row = data.add_row
    row['stim_time'] = '6515'
    row['run_start'] = '2400'
    row = data.add_row
    row['stim_time'] = '8115'
    row['run_start'] = '2400'
    row['sparse'] = '50'
    row = data.add_row
    row['stim_time'] = '9815'
    row['run_start'] = '2400'
    row = data.add_row
    row['stim_time'] = '12515'
    row['run_start'] = '2800'
    return data
  end
  
  def es(sym)
    CONST_EXPRS[sym][0]
  end
  
  def ev(sym)
    CONST_EXPRS[sym][1].call.to_s
  end
  
end