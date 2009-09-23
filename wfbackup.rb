#!/usr/bin/env ruby

# (c) Webforce Ltd, www.webforce.co.nz
# All Rights Reserved

require 'rubygems'
require 'optparse'

# gems
require 'rio'
require 'aws/s3'
require 'sequel'
require 'inifile'

# config/*
# ruby config
require 'config/config.rb'
# mysql config
config = IniFile.new("config/database.cnf")

require 'lib/webforce_backup.rb'

options = {
  :verbose => false, 
  :tmp_path => './tmp',
  :backup_path => './done',
  :db_user => config[:client]['user'], 
  :db_pass => config[:client]['password'], 
  :db_host => config[:client]['host'],
  :amazon_access_key_id => AMAZON_ACCESS_KEY_ID,
  :amazon_secret_access_key => AMAZON_SECRET_ACCESS_KEY,
  :bucket_name => BUCKET_NAME,
  :cleanup_days => 7}

OptionParser.new do |opts|
  opts.banner = "Usage: wfbackup.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-d", "--databases", "Backup Database Files") do |v|
    options[:run_database_backup] = v
  end

  opts.on("-u", "--upload", "Upload files in done to s3") do |v|
    options[:run_upload] = v
  end

  opts.on("-c", "--cleanup [DAYS]", Integer, "Remove files from S3 older than DAYS") do |v|
    options[:run_cleanup] = true
    options[:cleanup_days] = v || 7
  end
  
  opts.on("-f", "--full", "Full Run. Same as -d -u -c") do |v|
    options[:run_database_backup] = true
    options[:run_cleanup] = true
    options[:run_upload] = true
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

STDOUT.sync = true

wfbackup = Webforce::Backup.new(options)
