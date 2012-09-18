#!/usr/bin/env ruby
# encoding: UTF-8

# env['PATH_INFO']
# $LOAD_PATH << './lib'

require 'yunohost/functions'

#######################################
########## Arguments parsing ##########
#######################################

arguments = {
	:user 		=> ["add", "search", "info", "delete", "filterdelete"] 
	# :domain	=> []
	# :apps		=> []
}

usages = {
	:user_add 		=> "yunh user add <username,firstname,lastname,mail,password>",
	:user_search 		=> "yunh user search <ldap_filter> <attributes>",
	:user_info 		=> "yunh user info <uid>",
	:user_delete 		=> "yunh user delete <uids>",
	:user_filterdelete 	=> "yunh user filter-delete <filter>"
}

examples = {
	:user_add 		=> "yunh user add \"firstname=Homer,lastname=Simpson,username=homer,mail=homer@simpson.org,password=donuts\"",
	:user_search 		=> "yunh user search \"cn=Homer Simpson\" uid,mail",
	:user_info 		=> "yunh user info homer",
	:user_delete 		=> "yunh user delete homer lisa marge",
	:user_filterdelete 	=> "yunh user filter-delete (objectClass=inetOrgPerson)"
}

def parse_user_add(args)
	unless args.first.match(/^--/)
		attrs = {}
		args.first.split(",").each do |field|
			attrs[field.split("=").first.to_s] = field.split("=").last.to_s
		end
		if attrs["firstname"] and 
		   attrs["firstname"] and 
	           attrs["username"] and 
	           attrs["mail"] and 
		   attrs["password"] then
			user_add attrs
		else
			puts ERROR + "Missing field(s)"
			exit ERROR_ARGUMENTS
		end
	end
end

def parse_user_search(args)
	attributes = args.last ? args.last.split(",") : "dn"
	@@yunldap.search("ou=users," + LDAPDOMAIN, args.first, attributes, true)
end

def parse_user_info(args)
	user_info(args.first)
end

def parse_user_delete(args)
	user_delete(args)
end

def parse_user_filterdelete(args)
	user_filterdelete(args.first)
end


unless ARGV[0] and ARGV[1] and arguments[ARGV[0].to_sym] and arguments[ARGV[0].to_sym].include?(ARGV[1])
	puts ERROR + "Need help? Type 'man yunohost'"
	exit ERROR_ARGUMENTS
else
	key_name 	= ARGV[0] + "_" + ARGV[1]
	method_name = "parse_" + key_name
	ARGV.delete_at(0)
	ARGV.delete_at(0)
	unless ARGV.empty?
		self.send(method_name.to_sym, ARGV) # Call dynamic methods above
	else
		puts USAGE   + usages[key_name.to_sym]
		puts EXAMPLE + examples[key_name.to_sym]
		exit ERROR_ARGUMENTS
	end
end

exit 0
