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
require 'net/ldap'		# LDAP OM
require 'highline/import'	# Password Prompt


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

def ldap_add(dn, attrs_hash)
	begin
		@ldap.add(:dn => dn, :attributes => attrs_hash)
		puts "plop"
	rescue
		puts "Error: An error occured during LDAP entry creation\ndn: #{dn} \nattributes: \n#{attrs_hash}"
		exit 1
	end
end


### YunoHost specific functions ###
def user_add(attrs_hash)
	# is_valid(
	# 	attrs_hash["username"]	=> /^[a-z0-9_]$/
	# 	attrs_hash["mail"]	=> /^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,6}$/
	# )

	# is_unique(
	# 	:uid		=> attrs_hash["username"],
	# 	:cn 		=> attrs_hash["firstname"] + " " + attrs_hash["lastname"],
	# 	:mail 		=> attrs_hash["mail"],
	# 	:mailalias 	=> attrs_hash["mail"],
	# 	:mailforward	=> attrs_hash["mail"],
	# )

	dn = "cn=" + attrs_hash["firstname"] + " " + attrs_hash["lastname"] + ",ou=users," + LDAPDOMAIN

	attrs = {
		:objectclass 	=> ["mailAccount", "inetorgperson"],
		:givenName	=> attrs_hash["firstname"],
		:sn 		=> attrs_hash["lastname"],
		:displayName 	=> attrs_hash["firstname"] + " " + attrs_hash["lastname"],
		:cn 		=> attrs_hash["firstname"] + " " + attrs_hash["lastname"],
		:uid 		=> attrs_hash["username"],
		:userPassword 	=> "{MD5}" + Base64.encode64(Digest::MD5.digest(attrs_hash["password"])).chomp,
		:mail 		=> attrs_hash["mail"]
	}

	puts "yayaya"
	ldap_add(dn, attrs)
end

### Arguments parsing ###
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
	when "add"
		if ARGV[2] && !ARGV[2].match(/^--/)
			attrs = {}
			ARGV[2].split(",").each do |field|
				attrs[field.split("=").first.to_s] = field.split("=").last.to_s
			end
			if attrs["firstname"] && attrs["firstname"] && attrs["username"] && attrs["mail"] && attrs["password"]
				user_add attrs
			else
				puts "Error: Missing field(s)"
				exit 1
			end
		else
			puts "Usage: yunh user add <fields>\nExample: yunh user add \"firstname=Homer,lastname=Simpson,username=homer,mail=homer@simpson.org,password=donuts\""
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
