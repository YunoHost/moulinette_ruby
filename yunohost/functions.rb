# encoding: UTF-8

# YunoHost - Self-hosting for all
# Copyright (C) 2012  Kload <kload@kload.fr>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

DEBUG = false

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


