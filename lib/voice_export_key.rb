require 'digest/sha1'

module VoiceExportKey
	def self.strkey(login)
		Digest::SHA1.hexdigest login	
	end
end