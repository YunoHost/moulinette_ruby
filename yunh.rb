#!/usr/bin/env ruby
# encoding: UTF-8

# Remember list
# Environment variable : env['PATH_INFO'] 
# Arguments passed : ARGV
# Executed code : `ls -l`
# Include path : $LOAD_PATH << './lib'
# Relative path : require './ldap'

require 'rubygems'
require 'digest/md5'
require 'base64'

### Gem dependencies ###
require 'net/ldap' 			# LDAP OM
require 'highline/import' 	# Password Prompt


### LDAP Connection ###
LDAPDOMAIN = `slapcat -f /etc/ldap/slapd.conf | cut -d" " -f2 | grep ^dc -m1`
# LDAPDOMAIN = "dc=yunohost,dc=org"
LDAPPWD = ask("Enter LDAP admin password:  ") { |q| q.echo = false }

@ldap = Net::LDAP.new(:host => "localhost", :port => "389")
@ldap.auth "cn=admin," + LDAPDOMAIN, LDAPPWD

unless @ldap.bind
  puts "Error: " + @ldap.get_operation_result.message
  exit @ldap.get_operation_result.code
end

### Generic LDAP functions ###
def ldap_search(base, filter, attrs = "dn")
  begin
  	search = @ldap.search(:base => base, :attributes => attrs, :filter => filter, :return_result => true)
  rescue
  	puts "Error: Wrong search arguments \nfilter: #{filter} \nattributes: #{attrs}"
   	exit 1
  end
  search.each do |entry|
    attrs.each do |attr|
	  begin
	  	puts entry.send(attr.to_s)
	  rescue
	  	puts "Notice: Undefined attribute '#{attr}' for #{entry.dn}"    		
	  end
    end
  end

end

case ARGV[0]
when "user"
	case ARGV[1]
	when "search"
		if ARGV[2]
			attributes = ARGV[3] ? ARGV[3].split(",") : "dn"
			ldap_search("ou=users," + LDAPDOMAIN, ARGV[2], attributes)
		else
			puts "Usage: yunh user search <ldap_filter> <attributes>\nExample: yunh user search \"cn=Homer Simpson\" uid,mail"
			exit 1
		end
	else
		puts "Usage: yunh user search | add"
		exit 1
	end
else
	puts "Error: Need help? Type 'man yunohost'"
	exit 1
end