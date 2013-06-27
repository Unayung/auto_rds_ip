require "aws-sdk"
require "yaml"
require "sanitize"
require "open-uri"

### 1. set configuration and build a RDS instance ###
config = YAML::load(File.open("#{File.dirname(__FILE__)}/config/config.yml"))
### we need to execute code below, for each of the end-points ###
config["end_points"].each do |end_point|

  AWS.config({
    :access_key_id => config["access_key_id"],
    :secret_access_key => config["secret_access_key"],
    :max_retries => 3,
    :rds_endpoint => end_point
  })
  rds = AWS::RDS.new
  puts "==== Checking IP Address at #{Time.now} ===="
### 2. get current ip and check if changed ###
  ip_prompt = open("http://checkip.dyndns.org").readline
  current_ip = Sanitize.clean(ip_prompt).match(/\b(?:[0-9]{1,3}\.){3}[0-9]{1,3}\b/).to_s
  old_ip = File.open("#{File.dirname(__FILE__)}/old_ip.txt", "r").size > 0 ? File.open("#{File.dirname(__FILE__)}/old_ip.txt", "r").readline.chomp : "192.168.0.1"

  if old_ip == current_ip
    abort("==== IP address didn't change, happy coding :) ====")
  else
    puts("==== IP address changed, will do the rest for you ====")
    File.open("#{File.dirname(__FILE__)}/old_ip.txt", "w") do |file|  
      file.puts "#{current_ip}"  
    end
  end

### 3. check both ip address if already authorized ###
  check_flag = false
  response = rds.client.describe_db_security_groups(:db_security_group_name => config["security_group_name"])
  response[:db_security_groups].first[:ip_ranges].each do |ip_record|
    if ip_record.has_value?("#{current_ip}/32")    
      check_flag = true
      break
    else
      check_flag = false
    end

    if ip_record.has_value?("#{old_ip}/32")
      rds.client.revoke_db_security_group_ingress(:db_security_group_name => config["security_group_name"], :cidrip => "#{old_ip}/32")
    end
  end

### 4. authorizing if not in security groups
  if check_flag
    puts "==== current ip #{current_ip} was authorized, take a beer and relax ===="
  else
    puts "==== current ip #{current_ip} was not authorized, now authorizing for you ===="
    rds.client.authorize_db_security_group_ingress(:db_security_group_name => config["security_group_name"], :cidrip => "#{current_ip}/32")
    puts "==== current ip #{current_ip} authorized, have fun coding :) ===="
  end
  
end