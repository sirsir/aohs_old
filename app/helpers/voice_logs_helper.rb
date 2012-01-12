module VoiceLogsHelper

   def to_full_type(skt)
       case skt
       when 'n'
         return 'NG'
       when 'm'
         return 'MUST'
       when 'a'
         return 'ACTION'
       end
   end
   
end
