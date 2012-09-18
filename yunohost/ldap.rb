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

require 'rubygems'
require 'net/ldap'

class YunoHostLDAP
	attr_accessor :ldap

	def initialize
	    @ldap = Net::LDAP.new(:host => "localhost", :port => "389")
		@ldap.auth "cn=admin," + LDAPDOMAIN, LDAPPWD

		unless @ldap.bind
			puts ERROR + "" + @ldap.get_operation_result.message
			exit @ldap.get_operation_result.code
		end
	end

	def search(base, filter, attrs = "dn", display = false)
		begin
			search = @ldap.search(:base => base, :attributes => attrs, :filter => filter, :return_result => true)
		rescue
			puts ERROR + "Wrong search arguments \n   filter: #{filter} \n   attributes: #{attrs}"
			exit ERROR_ARGUMENTS
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

	def add(dn, attrs_hash)
		begin
			@ldap.add(:dn => dn, :attributes => attrs_hash)
			return true
		rescue
			puts ERROR + "An error occured during LDAP entry creation\n   dn: #{dn} \n   attributes: \n#{attrs_hash}"
			exit ERROR_LDAP
		end
	end

	def delete(dn)
		begin
			return true if @ldap.delete(:dn => dn)
		rescue
			puts ERROR + "An error occured during LDAP entry deletion\n   dn: #{dn}"
			exit ERROR_LDAP
		end
	end

	def validate(args)
		args.each do |key, value|
			next if key.match(/#{value}/)
			puts ERROR + "'#{key}' is invalid"
			exit ERROR_INVALID
		end
	end

	def validate_uniqueness(args)
		args.each do |key, value|
			next unless search(LDAPDOMAIN, key.to_s + "=" + value)
			puts ERROR + "the #{key} '#{value}' is already used"
			exit ERROR_EXISTS
		end
	end

end