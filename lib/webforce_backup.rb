#require './time_ago.rb'

module Webforce
  class Backup
    
    def initialize(options = {})
      @options = options
      begin
      AWS::S3::Base.establish_connection!(
        :access_key_id     => @options[:amazon_access_key_id],
        :secret_access_key => @options[:amazon_secret_access_key]
      )
      rescue Exception => e
        "ERROR: Can't connect to amazon #{e}"
        throw e
      end
      backup_databases! if @options[:run_database_backup]      
      upload_backups! if @options[:run_upload]      
      cleanup! if @options[:run_cleanup]      
    end
    

    
    def backup_databases!
      puts "Starting Backup of Databases" if v?
      date = Time.now.strftime("%d-%b-%Y")
      tmp_path = @options[:tmp_path]
      backup_path = @options[:backup_path]
      
      @db = Sequel.mysql(:host => @options[:db_host], :user => @options[:db_user], :password => @options[:db_pass])
      databases = @db.fetch("show databases")
      databases.map{|x| x[:Database]}.delete_if{|x| x == "information_schema"}.each do |db|
        file = "database-#{db}-#{date}.gz"
      	puts "dumping #{db} into #{tmp_path}/#{file}" if v?
      	`mysqldump --defaults-file=config/database.cnf #{db} | gzip > #{tmp_path}/#{file}`
      	puts "moving #{file} from #{tmp_path} to #{backup_path}" if v?
      	`mv #{tmp_path}/#{file} #{backup_path}/#{file}`
      	puts "finished dumping #{db}" if v?
      end # end databases.map
    end # end def backup_databases!
    
    def upload_backups!
      rio(@options[:backup_path]).files("*.gz").each do |backup_file|
        puts "Uploading up #{backup_file.to_s.split("/").last} to bucket #{@options[:bucket_name]}" if v?
        AWS::S3::S3Object.store(backup_file.to_s.split("/").last, open(backup_file.to_s), @options[:bucket_name])
        puts "done. Deleting source file" if v?
        backup_file.unlink
        puts "deleted" if v?
      end
    end
    
    def cleanup!
      puts "checking for old data .. " if v?
      AWS::S3::Bucket.find(@options[:bucket_name]).objects.each do |obj|
      	date = Time.parse(obj.about['last-modified'])
      	puts "age of #{obj.key} is #{time_ago(date)}" if v?
      end
    end
    
    private
    
    def v?
      @options[:verbose]
    end
    
    def time_ago(time) 
      seconds = Time.now - time
      puts seconds
      minutes = seconds / 60
      hours = minutes / 60 
      days = hours / 24
      weeks = days / 7
      years = weeks / 52
      "#{days.round} days / #{hours.round} hours / #{minutes.round} minutes"
    end
    
  end # end class Backup
end # end module Webforce
