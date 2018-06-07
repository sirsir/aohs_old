require 'multi_json'
require 'elasticsearch'
require 'hashie'
require 'json'

module AnalyticTrigger
  module ElsClient
  
    class DocSource < Hashie::Mash
    end
    
    class Base
      
      @client = nil
      @config = nil
      @is_new = false
      
      def setup_configuration 
        @config = {
          url: "#{Settings.server.es.host}",
          index: "#{Settings.server.es.prefix}_voice_logs",
          type: 'voice_log'
        }
        begin
          @client = Elasticsearch::Client.new({ :url => @config[:url] })
          @client.transport.reload_connections!
        rescue => e
          AnalyticTrigger.logger.error "Error ES connection #{e.message}"
        end
      end
      
      def initialize(id)
        setup_configuration
        @id = id
      end
      
      def exists?
        @client.exists? index: index_name, type: type_name, id: @id
      end
      
      def created?
        if exists?
          get_document
          return true
        end
        return false
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
        return @config[:type]
      end
  
    end
    
    class VoiceLogDocument < Base
      
      def update_asst_logs(logs=[])
        # replace logs by evaluation_plan_id
        unless @source["assessment_logs"].blank?
          form_id = (logs.map { |l| l[:evaluation_plan_id].to_i }).uniq
          @source["assessment_logs"].each do |log|
            next if form_id.include?(log["evaluation_plan_id"])
            logs << log
          end
        end
        @client.update index: index_name, type: type_name, id: @id, body: {
          script: "ctx._source.assessment_logs = params", params: { params: logs } 
        }
      end

      def update_dialog_logs(logs=[])
        @client.update index: index_name, type: type_name, id: @id, body: {
          script: "ctx._source.dialog_results = params", params: { params: logs } 
        }
      end

      def update_categories(ids=[])
        @client.update index: index_name, type: type_name, id: @id, body: {
          script: "ctx._source.call_categories = params", params: { params: ids } 
        }
      end
      
      def update_auto_taggings(tags={})
        @client.update index: index_name, type: type_name, id: @id, body: {
          script: "ctx._source.au_taggings = params", params: { params: tags } 
        }
      end
      
      #def update_words(words=[])
      #  #STDOUT.puts "Update call category to #{index_name}/#{type_name}/_#{@id}, #{words.inspect}"
      #  @client.update index: index_name, type: type_name, id: @id, body: {
      #    script: "ctx._source.words = params", params: { params: words } 
      #  }
      #end
      
      #def update_dialog_results(dialogs=[])
      #  @client.update index: index_name, type: type_name, id: @id, body: {
      #    script: "ctx._source.dialog_results = params", params: { params: dialogs } 
      #  }
      #end
      #
      #def update_call_reason(reason=[])
      #  @client.update index: index_name, type: type_name, id: @id, body: {
      #    script: "ctx._source.reasons = params", params: { params: reason } 
      #  }
      #end
      
      def update_field(field_name, data=[])
        # used for update date to field_name
        # field_name = []
        if ["reasons", "dialog_results", "personal_info", "product_tag"].include?(field_name)
          @client.update index: index_name, type: type_name, id: @id, body: {
            script: "ctx._source.#{field_name} = params", params: { params: data } 
          }
        end
      end
      
    end
    
    # end module
  end
end