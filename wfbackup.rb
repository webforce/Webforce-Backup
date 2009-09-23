#!/usr/bin/env ruby
require 'optparse'
options = {:verbose => false}
OptionParser.new do |opts|
  opts.banner = "Usage: wfbackup.rb [options]"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!

p options
p ARGV
