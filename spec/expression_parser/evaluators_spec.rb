# Part of the Optimus package for managing E-Prime data
# 
# Copyright (C) 2008-09 Board of Regents of the University of Wisconsin System
# 
# Written by Nathan Vack <njvack@wisc.edu>, at the Waisman Laborotory for Brain
# Imaging and Behavior, University of Wisconsin - Madison

require File.join(File.dirname(__FILE__),'../spec_helper')
require File.join(File.dirname(__FILE__), '../../lib/eprime')

require 'parsed_calculator'
require 'expression_parser/evaluators'
include EprimeTestHelper
include Eprime::ParsedCalculator::Evaluators

describe Prefix do
  describe 'negation' do
    before :all do
      @neg = Prefix::Neg
    end

    it "should negate numbers" do
      @neg.call(1).should == -1
    end
    
    it "should return NaN when negating non-numbers" do
      @neg.call("a").should be_nan
    end
  end
  
  describe 'boolean not' do
    before :all do
      @not = Prefix::Not
    end
    
    it "should work with booleans" do
      @not.call(true).should be_false
      @not.call(false).should be_true
    end
    
    it "should work with numbers" do
      @not.call(1).should be_false
      @not.call(0.0).should be_false
    end
    
    it "should work with strings" do
      @not.call("1").should be_false
      @not.call("").should be_true
    end
  end
end

describe Binary do
  describe 'addition' do
    before :all do
      @plus = Binary::Plus
    end
    
    it "should add numbers" do
      @plus.call(1, 1).should == 2
    end
    
    it "should return NaN when adding non-numbers" do
      @plus.call(1, 'a').should be_nan
    end
  end
  
  describe 'subtraction' do
    before :all do
      @minus = Binary::Minus
    end
    
    it "should subtract numbers" do
      @minus.call(2, 1).should == 1
    end
    
    it "should return NaN when subtracting non-numbers" do
      @minus.call(2, 'a').should be_nan
    end
  end
  
  describe 'multiplication' do
    before :all do
      @times = Binary::Times
    end
    
    it "should multiply numbers" do
      @times.call(2, 2).should == 4
    end
    
    it "should return NaN when multiplying non-numbers" do
      @times.call(2, 'a').should be_nan
    end
  end
  
  describe 'division' do
    before :all do
      @div = Binary::Div
    end
    
    it "should divide numbers" do
      @div.call(4, 2).should == 2
    end
    
    it "should return NaN when dividing non-numbers" do
      @div.call(2, 'a').should be_nan
    end
    
    it "should perform floating point division" do
      res = 1.0/3.0
      @div.call(1,3).should == res
    end
    
    it "should return NaN when dividing by 0" do
      @div.call(2,0).should be_nan
    end
  end
  
  describe 'concatenation' do
    before :all do
      @cat = Binary::Concat
    end
    
    it "should concatenate strings" do
      @cat.call("foo", "bar").should == "foobar"
    end
    
    it "should concatenate numbers" do
      @cat.call("foo", 2).should == "foo2"
    end
    
    it "should concatenate nil" do
      @cat.call("foo", nil).should == "foo"
    end
  end
  
  describe "modulo" do
    before :all do
      @mod = Binary::Mod
    end
    
    it "should mod ints" do
      @mod.call(5, 3).should == 2
    end
    
    it "should not mod strings" do
      @mod.call(5, 'a').should be_nan
    end
  end
  
  describe "and" do
    before :all do
      @and = Binary::And
    end
    
    it "should work with booleans" do
      @and.call(true, true).should be_true
      @and.call(false, true).should be_false
      @and.call(false, false).should be_false
    end
    
    it "should consider all numbers true" do
      @and.call(0.0, 1).should be_true
    end
    
    it "should consider blanks to be false" do
      @and.call('', true).should be_false
    end
  end
  
  describe "or" do
    before :all do
      @or = Binary::Or
    end
    
    it "should work with booleans" do
      @or.call(true, true).should be_true
      @or.call(true, false).should be_true
      @or.call(false, false).should be_false
    end
    
    it "should consider numbers true" do
      @or.call(0.0, 0.0).should be_true
    end
    
    it "should consider blanks false" do
      @or.call('', '').should be_false
    end
  end
  
  describe "comparisons" do
    nan = 0.0/0.0
    # We're just gonna loop through this table and check...
    comp_table = Binary::OpTable
    comp_ops = %w(= != > < >= <=)
    test_table = {
      :equal_nums => 
        {:lr => [1,1], :true_for => %w(= >= <=), :false_for => %w(!= > <)},
      :equal_strs => 
        {:lr => %w(a a), :true_for => %w(= >= <=), :false_for => %w(!= > <)},
      :equal_num_strnum =>
        {:lr => [1,'1'], :true_for => %w(= >= <=), :false_for => %w(!= > <)},
      :neq_str_num =>
        {:lr => [1, 'a'], :true_for => %w(!=), :false_for => %w(= > < >= <=)},
      :lt_nums => 
        {:lr => [1,2], :true_for => %w(!= < <=), :false_for => %w(= > >=)},
      :lt_num_strnum => 
        {:lr => [1,'2'], :true_for => %w(!= < <=), :false_for => %w(= > >=)},
      :lt_str =>
        {:lr => %w(a b), :true_for => %w(!= < <=), :false_for => %w(= > >=)},
      :gt_nums => 
        {:lr => [2,1], :true_for => %w(!= > >=), :false_for => %w(= < <=)},
      :gt_num_strnum => 
        {:lr => ['2',1], :true_for => %w(!= > >=), :false_for => %w(= < <=)},
      :gt_str =>
        {:lr => %w(b a), :true_for => %w(!= > >=), :false_for => %w(= < <=)},
      :nans =>
        {:lr => [nan,nan], :true_for => %w(!=), :false_for => %w(= > < >= <=)},
    }
    
    test_table.each do |name, test_data|
      true_tests = test_data[:true_for]
      false_tests = test_data[:false_for]
      describe "between #{test_data[:lr].inspect}" do
        it "should test all comparisons" do
          (true_tests+false_tests).sort.should == comp_ops.sort
        end
        true_tests.each do |test_name|
          it "should be true for #{test_name}" do
            comp_table[test_name.to_sym].call(*test_data[:lr]).should be_true
          end
        end
        false_tests.each do |test_name|
          it "should be false for #{test_name}" do
            comp_table[test_name.to_sym].call(*test_data[:lr]).should be_false
          end
        end
      end # describe
    end# table.each
  end
end
