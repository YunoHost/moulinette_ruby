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
 

$LOAD_PATH << '..'
require 'test/unit'
require 'yunohost/functions'

@@user_hash = {
	"username"  => "toto",
	"mail"      => "toto@tata.net",
	"lastname"  => "Tata Titi",
	"firstname" => "Toto",
	"password"  => "yayaya"
}
 
class TestYunoHostFunctions < Test::Unit::TestCase

	def test_ldap_search

    	puts "\n\n====== ldap_search ======\n"
		result = [{
			"objectclass" 	=> ["mailAccount", "organizationalRole", "posixAccount", "simpleSecurityObject"],
			"dn" 	      	=> "cn=admin," + LDAPDOMAIN.chomp
		  },
		  {
			"objectclass" 	=> ["sudoRole", "top"],
			"dn"		=> "cn=admin,ou=sudo," + LDAPDOMAIN.chomp
		  },
		  {
			"objectclass" 	=> ["groupOfNames", "top"],
			"dn"		=> "cn=admin,ou=groups," + LDAPDOMAIN.chomp
		  }]

		assert_equal(result, @@yunoldap.search(LDAPDOMAIN, "(cn=admin)", ["dn", "objectclass"], false))
	end
 
	def test_user_add

    	puts "\n\n====== user_add ======\n"
		result = {
			:dn	=> "cn=Toto Tata Titi,ou=users," + LDAPDOMAIN,
			:attrs 	=> {
				:objectclass 	=> ["mailAccount", "inetorgperson"],
				:uid 		=> "toto",
				:givenName   	=> "Toto",
				:sn 		=> "Tata Titi",
				:mail 		=> "toto@tata.net",
				:displayName 	=> "Toto Tata Titi",
				:userPassword 	=> "{MD5}odEjpjk2q77oeCPi8a/6mw==",
				:cn 		=> "Toto Tata Titi"
			 }
		}
		
		user_delete("toto") if @@yunoldap.search(LDAPDOMAIN, "(uid=toto)")
		assert_equal(result, user_add(@@user_hash))
	end

	def test_user_info

    	puts "\n\n====== user_info ======\n"
		result = {
			"givenName" => "Toto",
			"mailalias" => "none",
			"uid"       => "toto",
			"mail"      => "toto@tata.net",
			"sn"        => "Tata Titi"
		}

		user_add(@@user_hash) unless @@yunoldap.search(LDAPDOMAIN, "(uid=toto)")
		assert_equal(result, user_info("toto"))
	end
 
	def test_user_delete

    	puts "\n\n====== user_delete ======\n"
		user_add(@@user_hash) unless @@yunoldap.search(LDAPDOMAIN, "(uid=toto)")
		assert_equal(true, user_delete("toto"))
	
	end

	def test_user_filterdelete

    	puts "\n\n====== user_filterdelete ======\n"
		user_add(@@user_hash) unless @@yunoldap.search(LDAPDOMAIN, "(uid=toto)")
		assert_equal(true, user_filterdelete("(uid=toto)"))
	end

	def test_user_populate

    	puts "\n\n====== user_populate ======\n"
		result = [{
			"cn"		=> "Toto Tata Titi",
			"givenName"	=> "Toto",
			"displayName"	=> "Toto Tata Titi",
			"sn"		=> "Tata Titi",
			"mail"		=> "toto@tata.net",
			"objectClass"	=> ["mailAccount", "inetOrgPerson"],
			"uid"		=> "toto",
			"userPassword"	=> "{MD5}odEjpjk2q77oeCPi8a/6mw==",
			"dn"		=> "cn=Toto Tata Titi,ou=users,dc=gavoty,dc=net"
		}]

		user_add(@@user_hash) unless @@yunoldap.search(LDAPDOMAIN, "(uid=toto)")
		assert_equal(result, user_populate("toto"))
	end
  
end
