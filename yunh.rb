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
require 'pp' # Just pretty printer :)


#######################################
########### Gem dependencies ##########
#######################################

require 'net/ldap'		# LDAP OM
require 'highline/import'	# Password Prompt


#######################################
########### LDAP Connection ###########
#######################################

ERROR = "  \033[31mError:\033[00m "
NOTICE = "  \033[34mNotice:\033[00m "
SUCCESS = "  \033[32mSuccess:\033[00m "
USAGE = "  \033[35mUsage:\033[00m "
EXAMPLE = "  \033[33mExample:\033[00m "

LDAPDOMAIN = `slapcat -f /etc/ldap/slapd.conf | cut -d" " -f2 | grep ^dc -m1`
# LDAPDOMAIN = "dc=yunohost,dc=org"
LDAPPWD = ask("Enter LDAP admin password:  ") { |q| q.echo = false }

@ldap = Net::LDAP.new(:host => "localhost", :port => "389")
@ldap.auth "cn=admin," + LDAPDOMAIN, LDAPPWD

unless @ldap.bind
	puts ERROR + "" + @ldap.get_operation_result.message
	exit @ldap.get_operation_result.code
end



#######################################
######## Generic LDAP functions #######
#######################################

def ldap_search(base, filter, attrs = "dn", display = false)
	begin
		search = @ldap.search(:base => base, :attributes => attrs, :filter => filter, :return_result => true)
	rescue
		puts ERROR + "Wrong search arguments \nfilter: #{filter} \nattributes: #{attrs}"
		exit 1
	end
	result = []
	i = 0
	search.each do |entry|
		result[i] = {}
		attrs.each do |attr|
			begin
				row = entry.send(attr.to_s)
				puts row if display 
				result[i][attr] = row[1] ? row : row.to_s
			rescue
				puts NOTICE + "Undefined attribute '#{attr}' for #{entry.dn}"				
			end
		end
		i += 1
	end
	return result.empty? ? false : result
end

def ldap_add(dn, attrs_hash)
	begin
		@ldap.add(:dn => dn, :attributes => attrs_hash)
		return true
	rescue
		puts ERROR + "An error occured during LDAP entry creation\ndn: #{dn} \nattributes: \n#{attrs_hash}"
		exit 1
	end
end

def ldap_delete(dn)
	begin
		return true if @ldap.delete(:dn => dn)
	rescue
		puts ERROR + "An error occured during LDAP entry deletion\ndn: #{dn}"
		exit 1
	end
end

def validate(args)
	args.each do |key, value|
		next if key.match(/#{value}/)
		puts ERROR + "'#{key}' is invalid"
		exit 1
	end
end

def validate_uniqueness(args)
	args.each do |key, value|
		next unless ldap_search(LDAPDOMAIN, key.to_s + "=" + value)
		puts ERROR + "the #{key} '#{value}' is already used"
		exit 1
	end
end


#######################################
##### YunoHost specific functions #####
#######################################

def user_add(attrs_hash)

	validate({
		attrs_hash["username"]	=> /^[a-z0-9_]+$/,
		attrs_hash["mail"]	=> /^[\w.-]+@[\w.-]+\.[a-zA-Z]{2,6}$/
	})

	validate_uniqueness({
		:uid		=> attrs_hash["username"],
		:cn 		=> attrs_hash["firstname"] + " " + attrs_hash["lastname"],
		:mail 		=> attrs_hash["mail"],
		:mailalias 	=> attrs_hash["mail"],
		# :mailforward	=> attrs_hash["mail"],
	})

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

	if ldap_add(dn, attrs)
		win_msg = SUCCESS + "User successfully created !\n"
		attrs_hash.each do |key, value|
			win_msg << "\n\033[35m  " << key.dup.to_s.capitalize! << ": \033[00m" << value.to_s
		end
		puts win_msg
	end
end

def user_populate(uid)
	user_attrs = ["dn", "cn", "uid", "userPassword", "objectClass", "mail", "givenName", "sn", "displayName", "mailalias"]
	if user = ldap_search("ou=users," + LDAPDOMAIN, "uid=" + uid, user_attrs)
		return user
	else
		puts ERROR + "User '#{uid}' doesn't exists"
		exit 1
	end
end

def user_info(uid)
	info_attrs = ["givenName", "sn", "mail", "mailalias", "uid"]
	if user = ldap_search("ou=users," + LDAPDOMAIN, "uid=" + uid, info_attrs)
		user = user[0]
		user["mail"] = user["mail"].join(", ") if user["mail"].kind_of?(Array)
		if user["mailalias"]
			user["mailalias"] = user["mailalias"].join(", ") if user["mailalias"].kind_of?(Array)
		else
			user["mailalias"] = "none"
		end

		puts "\033[35m  Username: \033[00m" << user["uid"]
		puts "\033[35m  Firstname: \033[00m" << user["givenName"]
		puts "\033[35m  Lastname: \033[00m" << user["sn"]
		puts "\033[35m  Mail: \033[00m" << user["mail"]
		puts "\033[35m  Mail aliases: \033[00m" << user["mailalias"]
		return user
	else
		puts ERROR + "User '#{uid}' doesn't exists"
		exit 1
	end
end

def user_delete(uids)
	uids.each do |uid|
		if result = ldap_search("ou=users," + LDAPDOMAIN, "uid=" + uid, "dn")
			puts SUCCESS + "User '#{uid}' successfully deleted !" if ldap_delete(result[0]["dn"])
		else
			puts ERROR + "User '#{uid}' doesn't exists"
			exit 1
		end
	end
end

def user_filter_delete(filter)
	if result_array = ldap_search("ou=users," + LDAPDOMAIN, filter.to_s, "dn")
		result_array.each do |result|
			puts SUCCESS + "'#{result["dn"]}' successfully deleted !" if ldap_delete(result["dn"])
		end
	else
		puts ERROR + "No user found"
		exit 1
	end
end


#######################################
########## Arguments parsing ##########
#######################################

case ARGV[0]
when "user"
	case ARGV[1]
	when "search"
		if ARGV[2]
			attributes = ARGV[3] ? ARGV[3].split(",") : "dn"
			ldap_search("ou=users," + LDAPDOMAIN, ARGV[2], attributes, true)
		else
			puts USAGE + "yunh user search <ldap_filter> <attributes>"
			puts EXAMPLE + "yunh user search \"cn=Homer Simpson\" uid,mail"
			exit 1
		end
	when "add"
		if ARGV[2] && !ARGV[2].match(/^--/)
			attrs = {}
			ARGV[2].split(",").each do |field|
				attrs[field.split("=").first.to_s] = field.split("=").last.to_s
			end
			if attrs["firstname"] and attrs["firstname"] and attrs["username"] and attrs["mail"] and attrs["password"]
				user_add attrs
			else
				puts ERROR + "Missing field(s)"
				exit 1
			end
		else
			puts USAGE + "yunh user add <username,firstname,lastname,mail,password>"
			puts EXAMPLE + "yunh user add \"firstname=Homer,lastname=Simpson,username=homer,mail=homer@simpson.org,password=donuts\""
			exit 1
		end
	when "info"
		if ARGV[2]
			user_info(ARGV[2])
		else
			puts USAGE + "yunh user info <uid>"
			puts EXAMPLE + "yunh user info homer"
			exit 1
		end
	when "delete"
		if ARGV[2]
			ARGV.delete_at(0)
			ARGV.delete_at(0)
			user_delete(ARGV)
		else
			puts USAGE + "yunh user delete <uid>"
			puts EXAMPLE + "yunh user delete homer lisa marge"
			exit 1
		end
	when "filter-delete"
		if ARGV[2]
			user_filter_delete(ARGV[2])
		else
			puts USAGE + "yunh user filter-delete <filter>"
			puts EXAMPLE + "yunh user filter-delete (objectClass=inetOrgPerson)"
			exit 1
		end
	else
		puts USAGE + "yunh user search | add | delete | filter-delete"
		exit 1
	end
else
	puts ERROR + "Need help? Type 'man yunohost'"
	exit 1
end

exit 0
