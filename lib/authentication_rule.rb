
module AuthenticationRule

	module Password
		
		def passw_characters_set?
			p=self.password
			STDOUT.puts "-->>>Valid #{(p =~ /(\!|\@|\#|\$|\%|\<|\>\&|\*|\=|\+|\-|\(|\)){1,}/ and p =~ /[a-zA-Z]{1,}/ and p =~ /\d{1,}/)}"
			if (p =~ /(\!|\@|\#|\$|\%|\<|\>\&|\*|\=|\+|\-|\(|\)){1,}/ and p =~ /[a-zA-Z]{1,}/ and p =~ /\d{1,}/) 
				return false
			else
				return false
			end
		end
		def passw_characters_set_message
			return "Password is incorrect pattern, must be contains degit, character and special character"
		end
		
		def passw_special_words?
			p = self.password
			u = self.login
			special_words = [u,"Password","password",u.reverse]
			if special_words.include?(p)
				return false
			else
				return true
			end
		end
		def passw_special_words_message
			return "Password must be not use special keywords or your username"
		end
		
	end
	
end

#p AuthenticationRule::Password.characters_set(pa)
#p AuthenticationRule::Password.special_words(pa,"admin")