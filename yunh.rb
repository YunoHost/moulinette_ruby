#!/usr/bin/env ruby
# encoding: UTF-8

# Remember list
# Environment variable : env['PATH_INFO']
# Arguments passed : ARGV
# Executed code : `ls -l`
# Include path : $LOAD_PATH << './lib'
# Relative path : require './ldap'

require 'rubygems'
require 'pp' 				# Just pretty printer :)
require 'yunohost/functions'

#######################################
########## Arguments parsing ##########
#######################################


def parse_user_info(args)
	if args[0]
		user_info(args[0])
	else
		puts USAGE + "yunh user info <uid>"
		puts EXAMPLE + "yunh user info homer"
		exit ERROR_ARGUMENTS
	end
end

arguments = {
	:user 		=> ["add", "search", "info", "delete", "filter-delete"] 
	# :domain	=> []
	# :apps 		=> []
}

ARGV[0].each.to_s

puts arguments[ARGV[0].to_sym]

unless ARGV[0] and ARGV[1] and arguments[ARGV[0].to_sym] and arguments[ARGV[0].to_sym].include?(ARGV[1])
	puts ERROR + "Need help? Type 'man yunohost'"
	exit ERROR_ARGUMENTS
else
	method_name = "parse_" + ARGV[0] + "_" + ARGV[1]
	ARGV.delete_at(0)
	ARGV.delete_at(0)
	self.send(method_name.to_sym, ARGV)
end


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
			exit ERROR_ARGUMENTS
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
				exit ERROR_ARGUMENTS
			end
		else
			puts USAGE + "yunh user add <username,firstname,lastname,mail,password>"
			puts EXAMPLE + "yunh user add \"firstname=Homer,lastname=Simpson,username=homer,mail=homer@simpson.org,password=donuts\""
			exit ERROR_ARGUMENTS
		end
	when "info"
		if ARGV[2]
			user_info(ARGV[2])
		else
			puts USAGE + "yunh user info <uid>"
			puts EXAMPLE + "yunh user info homer"
			exit ERROR_ARGUMENTS
		end
	when "delete"
		if ARGV[2]
			ARGV.delete_at(0)
			ARGV.delete_at(0)
			user_delete(ARGV)
		else
			puts USAGE + "yunh user delete <uid>"
			puts EXAMPLE + "yunh user delete homer lisa marge"
			exit ERROR_ARGUMENTS
		end
	when "filter-delete"
		if ARGV[2]
			user_filter_delete(ARGV[2])
		else
			puts USAGE + "yunh user filter-delete <filter>"
			puts EXAMPLE + "yunh user filter-delete (objectClass=inetOrgPerson)"
			exit ERROR_ARGUMENTS
		end
	else
		puts USAGE + "yunh user search | add | delete | filter-delete"
		exit ERROR_ARGUMENTS
	end
else
	puts ERROR + "Need help? Type 'man yunohost'"
	exit ERROR_ARGUMENTS
end

exit 0
