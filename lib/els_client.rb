require 'multi_json'
require 'elasticsearch'
require 'hashie'
require 'json'

module ElsClient

  class DocSource < Hashie::Mash
  end
  
  class Base
    
    @client = nil
    @config = nil
    @is_new = false
    
    def self.configuration
      return {
        url:   Settings.server.es.host.to_s,
        index: index_name,
        type:  type_name
      }
    end
    
    def self.index_name
      case type_name
      when "message_log", "keyword_log", "recommendation_log"
        return "#{Settings.server.es.prefix}_message_logs"
      else
        return "#{Settings.server.es.prefix}_voice_logs"
      end
    end
    
    def self.type_name(name=self.name)
      case name
      when /(ActivityLogDocument)/
        return "user_activity_log"
      when /(VoiceLogDocument)/
        return "voice_log"
      when /(AssessmentRule)/
        return "assessment_rule"
      when /(MessageLogDocument)/
        return "message_log"
      end
      return self.name.downcase
    end
    
    def self.full_url
      # http:<host>:<port>/<index>/<type>
      
    end
    
    def setup_configuration 
      @config = self.class.configuration
      begin
        @client = Elasticsearch::Client.new({ :url => @config[:url] })
        @client.transport.reload_connections!
      rescue => e
        STDERR.puts "Error ES connection #{e.message}"
      end
    end
        
    def initialize(params=nil)
      setup_configuration
      if params.is_a?(Integer)
        @id = params.to_i
      else
        if params.is_a?(Hash)
          @object_params = params
        else
          raise "Invalid parameter for ElsClient"
        end
      end
    end
    
    def exists?
      @client.exists? index: index_name, type: type_name, id: @id
    end
    
    def get_document
      if exists?
        result = @client.get index: index_name, type: type_name, id: @id
        @source = DocSource.new(result["_source"])
      else
        @is_new = true
      end
    end
  
    def index_name
      return @config[:index]
    end
    
    def type_name
      return self.class.type_name(self.class.name)
    end
    
    def get_object_id
      if @object_params.has_key?("id") and not @object_params["id"].blank?
        @id = @object_params["id"]
      end
    end
    
    def create
      if defined?(@object_params)
        get_object_id
        result = @client.index index: index_name, type: type_name, id: @id, body: @object_params
      end
    end
    
    def delete
      @client.delete index: index_name, type: type_name, id: @id
    end
    
  end
  
  class AssessmentRule < Base
    
  end
  
  class ActivityLogDocument < Base
    
  end
  
  class MessageLogDocument < Base
      
  end
  
  class VoiceLogDocument < Base
    
    def update_categories(ids=[])
      #STDOUT.puts "Update call category to #{index_name}/#{type_name}/_#{@id}, #{ids.inspect}"
      @client.update index: index_name, type: type_name, id: @id, body: {
        script: "ctx._source.call_categories = params", params: { params: ids } 
      }
    end
    
    def update_words(words=[])
      #STDOUT.puts "Update call category to #{index_name}/#{type_name}/_#{@id}, #{words.inspect}"
      @client.update index: index_name, type: type_name, id: @id, body: {
        script: "ctx._source.words = params", params: { params: words } 
      }
    end
    
    def update_dialog_results(dialogs=[])
      @client.update index: index_name, type: type_name, id: @id, body: {
        script: "ctx._source.dialog_results = params", params: { params: dialogs } 
      }
    end

    def update_call_reason(reason=[])
      @client.update index: index_name, type: type_name, id: @id, body: {
        script: "ctx._source.reasons = params", params: { params: reason } 
      }
    end
    
    def update_transcription(trans)
      # update edited transcription which is updated by user
      # this result must not replace result from speechserver
      edited_trans = []
      if defined? @source.edited_transcriptions and not @source.edited_transcriptions.nil?
        edited_trans = @source.edited_transcriptions
      end
      trx_updated = false
      trx_msec = trans[:start_sec].to_f * 1000
      trx_channel = trans[:channel].to_i
      trx_text = trans["text"].chomp.strip
      edited_trans.each_with_index do |trx,i|
        if trx["start_msec"] == trx_msec and trx_channel == trx["channel"]
          if trx_text == "<delete>"
            edited_trans.delete_at(i)
          else
            edited_trans[i]["text"] = trx_text
            edited_trans[i]["updated_by"] = trans["updated_by"]
            edited_trans[i]["updated_at"] = trans["updated_at"]
          end
          trx_updated = true
          break
        end
      end
      if not trx_updated and not trx_text == "<delete>"
        edited_trans << {
          start_msec: trx_msec,
          channel: trx_channel,
          text: trx_text,
          updated_by: trans["updated_by"],
          updated_at: trans["updated_at"]
        }
      end
      update_field("edited_transcriptions", edited_trans)
    end
    
    def update_field(field_name, data=[])
      # used for update date to field_name
      # field_name = []
      if ["reasons", "dialog_results", "personal_info", "product_tag", "edited_transcriptions"].include?(field_name)
        @client.update index: index_name, type: type_name, id: @id, body: {
          script: "ctx._source.#{field_name} = params", params: { params: data } 
        }
      end
    end
    
    # maintenance methods
    # remove unnessary field/data
    
    def remove_raw_result
      # remove raw result 
      unless @source.recognition_results.blank?
        data = @source.recognition_results.map { |d|
          d.delete("raw_result")
          d
        }
        res = @client.update index: index_name, type: type_name, id: @id, body: {
          script: "ctx._source.recognition_results = params", params: { params: data }
        }
      end
    end
    
    # end class
  end
  
  # end module
end