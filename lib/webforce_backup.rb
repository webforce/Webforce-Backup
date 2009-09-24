# (c) Webforce Ltd, www.webforce.co.nz
# All Rights Reserved

module Webforce
  class Backup
    
    def initialize(options = {})
      @options = options
      
      # connect to S3
      AWS::S3::Base.establish_connection!(
        :access_key_id     => @options[:amazon_access_key_id],
        :secret_access_key => @options[:amazon_secret_access_key]
      )
      
      # connect to database
      
      @db = Sequel.mysql(:host => @options[:db_host], :user => @options[:db_user], :password => @options[:db_pass])
      
      # run 
      backup_databases! if @options[:run_database_backup]      
      backup_directories! if @options[:run_archive]      
      upload_backups! if @options[:run_upload]      
      cleanup! if @options[:run_cleanup]      
    end
    

    
    def backup_databases!
      puts "Backing up databases:"
      date = Time.now.strftime("%d-%b-%Y")
      tmp_path = @options[:tmp_path]
      backup_path = @options[:backup_path]
      if @options[:databases].size < 1
        @options[:databases] = @db.fetch("show databases").map{|x| x[:Database]}.delete_if{|x| x == "information_schema"}
      end  
      @options[:databases].each do |db|
        file = "database-#{db}-#{date}.gz"
      	puts "dumping #{db} into #{tmp_path}/#{file}" if v?
      	`mysqldump --defaults-file=config/database.cnf #{db} | gzip > #{tmp_path}/#{file}`
      	puts "moving #{file} from #{tmp_path} to #{backup_path}" if v?
      	`mv #{tmp_path}/#{file} #{backup_path}/#{file}`
      	puts "finished dumping #{db}" if v?
      	print " #{db} ✔"
      end # end databases.map
      print " ... done\n"
    end # end def backup_databases!
    
    def upload_backups!
      puts "Starting Upload: "
      rio(@options[:backup_path]).files("*.gz").each do |backup_file|
        filename = backup_file.to_s.split("/").last #FIXME - use proper platform independent way
        puts "Uploading up #{filename} to bucket #{@options[:bucket_name]}" if v?
        print " #{filename} ✔ "
        AWS::S3::S3Object.store(filename, open(backup_file.to_s), @options[:bucket_name])
        puts "done. Deleting source file" if v?
        backup_file.unlink
        puts "deleted" if v?
      end
      print " ... done\n"
    end
    
    def cleanup!
      puts "Starting Cleanup:"
      puts "checking for backups older than #{@options[:cleanup_days]} old " if v?
      AWS::S3::Bucket.find(@options[:bucket_name]).objects.each do |obj|
        seconds_ago = Time.now - Time.parse(obj.about['last-modified'])
      	puts "age of #{obj.key} is #{time_ago(seconds_ago)}" if v?
      	
      	if seconds_ago > 60 * 60 * 24 * @options[:cleanup_days]
      	  puts "DELETING #{obj.key}" if v?
      	  print " deleted: #{obj.key} "
      	  obj.delete
      	else
      	  puts "not deleting #{obj.key}" if v?
      	end
      end
      print " ... done\n"
    end
    
    def backup_directories!
      puts "Backing up directories:"
      date = Time.now.strftime("%d-%b-%Y")
      @options[:dirs].each do |dir|
        verbose = @options[:verbose] ? 'v' : ''
        filename = "dir-#{dir[:name]}-#{date}.tar.gz"  
        cmd = "tar -c#{verbose}zf #{@options[:tmp_path]}/#{filename} #{dir[:dir]}"
        puts "running command: #{cmd}" if v?
        `#{cmd}`
	`mv #{@options[:tmp_path]}/#{filename} #{@options[:backup_path]}/`
 	print " #{dir[:dir]} ✔ "
      end
      print " ... done \n"
    end
    
    private
    
    def v?
      @options[:verbose]
    end
    
    def time_ago(seconds) # todo make this better
      minutes = seconds / 60
      hours = minutes / 60
      days = hours / 24
      weeks = days / 7
      years = weeks / 52
      "#{days.round} days / #{hours.round} hours / #{minutes.round} minutes"
    end
    
  end # end class Backup
end # end module Webforce
