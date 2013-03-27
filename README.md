## Auto RDS IP

It's because we don't have static-ip address, so we have to manually add current ip  
to Amazon RDS's db security group, almost EVERYDAY. It's so stupid and annoying.  

we use amazon's aws-sdk-ruby for manipulating AWS RDS

### Preparation

1. gem install aws-sdk
2. gem install sanitize

### Usage

1. clone this project  
2. set your credentials in config/config.yml
3. execute /path/to/ruby auto_rds_ip.rb
4. you could using whenever gem to make this a cronjob and just enjoy