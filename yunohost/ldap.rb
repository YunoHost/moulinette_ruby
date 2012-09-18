# encoding: UTF-8

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