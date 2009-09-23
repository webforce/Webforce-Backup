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

require 'lib/wfbackup_class.rb'

options = {
  :verbose => false, 
  :tmp_path => './tmp',
  :backup_path => './done'
  :db_user => config[:client]['user'], 
  :db_pass => config[:client]['password'], 
  :db_host => config[:client]['host'],
  :amazon_access_key_id => AMAZON_ACCESS_KEY_ID,
  :amazon_secret_access_key => AMAZON_SECRET_ACCESS_KEY,
  :bucket_name => BUCKET_NAME}

OptionParser.new do |opts|
  opts.banner = "Usage: wfbackup.rb [options]"
  opts.on("-v", "--[no-]verbose", "Run verbosely") do |v|
    options[:verbose] = v
  end
end.parse!

wfbackup = Webforce::Backup.new(options)
#wfbackup.backup_databases!
