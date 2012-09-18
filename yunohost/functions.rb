# encoding: UTF-8
DEBUG = true

require 'rubygems'
require 'highline/import'	# Temporary password prompt
require 'pp' if DEBUG

require 'yunohost/ldap'
require 'yunohost/user'
# require 'yunohost/domain'
# require 'yunohost/app'
# require 'yunohost/system'

ERROR 	= "  \033[31m\033[1mError:\033[m "
NOTICE 	= "  \033[34m\033[1mNotice:\033[m "
SUCCESS = "  \033[32m\033[1mSuccess:\033[m "
USAGE 	= "  \033[35m\033[1mUsage:\033[m "
EXAMPLE = "  \033[33m\033[1mExample:\033[m "

ERROR_LDAP 	= 50
ERROR_ARGUMENTS = 60
ERROR_INVALID 	= 70
ERROR_EXISTS 	= 80
ERROR_NOT_FOUND = 90


LDAPDOMAIN = `slapcat -f /etc/ldap/slapd.conf | cut -d" " -f2 | grep ^dc -m1`
LDAPPWD = ask("Enter LDAP admin password:  ") { |q| q.echo = false } # Temporary password prompt

# LDAPDOMAIN = "dc=yunohost,dc=org"
# LDAPPWD = `cat /etc/yunohost/moulinette`

@@yunoldap = YunoHostLDAP.new


