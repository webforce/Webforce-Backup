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
# mysql config
db_config = IniFile.new("config/database.cnf")
@dirs = []
require 'config/config.rb'

require 'lib/webforce_backup.rb'

options = {
  :verbose => false, 
  :tmp_path => './tmp',
  :backup_path => './done',
  :db_user => db_config[:client]['user'], 
  :db_pass => db_config[:client]['password'], 
  :db_host => db_config[:client]['host'],
  :amazon_access_key_id => AMAZON_ACCESS_KEY_ID,
  :amazon_secret_access_key => AMAZON_SECRET_ACCESS_KEY,
  :bucket_name => BUCKET_NAME,
  :cleanup_days => 7,
  :dirs => @dirs,
  :databases => []}

OptionParser.new do |opts|
  opts.banner = "Usage: wfbackup.rb [options]"

  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end

  opts.on("-d", "--databases", "Backup Database Files") do |v|
    options[:run_database_backup] = v
  end
  opts.on("-s DB1,DB2,DB3", "--specific DB1,DB2,DB3", "Backup specific databases rather than all.") do |v|
    options[:run_database_backup] = true
    options[:databases] = v.split(',')
  end
  opts.on("-u", "--upload", "Upload files in done to s3") do |v|
    options[:run_upload] = v
  end
  
  opts.on("-c", "--cleanup [DAYS]", Integer, "Remove files from S3 older than DAYS") do |v|
    options[:run_cleanup] = true
    options[:cleanup_days] = v || 7
  end

  opts.on('-a', '--archive', 'Archive Directories specified in config') do |v|
    options[:run_archive] = v
  end
  
  opts.on("-f", "--full", "Full Run. Same as -d -u -c") do |v|
    options[:run_database_backup] = true
    options[:run_cleanup] = true
    options[:run_upload] = true
    options[:run_archive] = true
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!
STDOUT.sync = true
wfbackup = Webforce::Backup.new(options)
