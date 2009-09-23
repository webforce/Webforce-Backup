#!/usr/bin/env ruby

# (c) 2007, Webforce Ltd, www.webforce.co.nz
# All Rights Reserved


## CONFIG END ##

require 'rubygems'

# gems
require 'rio'
require 'aws/s3'
require 'sequel'
require 'inifile'

# config/*
require 'config/config.rb'

# lib/*
require 'lib/time_ago.rb'

config = IniFile.new("database.cnf")
DB_USER =  config[:client]['user']
DB_PASS =  config[:client]['password']
DB_HOST =  config[:client]['host']


dow = Time.now.strftime("%a")
date = Time.now.strftime("%d-%b-%Y")

DB = Sequel.mysql(:host => DB_HOST, :user => DB_USER, :password => DB_PASS)

databases = DB.fetch("show databases")
databases.map{|x| x[:Database]}.delete_if{|x| x == "information_schema"}.each do |db|
	puts "dumping #{db}"
	file = "database-#{db}-#{date}.gz"
	`mysqldump --defaults-file=database.cnf #{db} | gzip > tmp/#{file}`
	`mv tmp/#{file} done/#{file}`
	puts "done"
end

AWS::S3::Base.establish_connection!(
  :access_key_id     => AMAZON_ACCESS_KEY_ID,
  :secret_access_key => AMAZON_SECRET_ACCESS_KEY
)



puts "Day is #{dow}, backup bucket : #{BUCKET_NAME}"

  rio("./done/").files("*.gz").each do |backup_file|
    puts "Uploading up #{backup_file.to_s.split("/").last} ... "
    AWS::S3::S3Object.store(backup_file.to_s.split("/").last, open(backup_file.to_s), BUCKET_NAME)
    backup_file.unlink
  end

puts "checking for old data .. "
AWS::S3::Bucket.find(BUCKET_NAME).objects.each do |obj|
	date = Time.parse(obj.about['last-modified'])
	puts "age is #{time_ago(date)}"
end

puts "All done"

