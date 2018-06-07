require 'net/ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable
      
      LDAP_ATTRS = [
        "accountExpires","objectCategory","objectClass",
        "mail","sAMAccountName","sAMAccountType",
        "userPrincipalName","displayName",
        "memberOf","employeeID","title","department"
      ]
      
      def authenticate!
        if params[:user] and Settings.ldap_auth.enable
          
          config = {
            host: Settings.ldap_auth.host,
            port: Settings.ldap_auth.port,
            base: Settings.ldap_auth.base
          }
          
          Rails.logger.info "Trying to authentication using LDAP:#{config.inspect}"
          
          config[:auth] = {
            method: :simple,
            username: username,
            password: password
          }
          
          ldap = Net::LDAP.new config
          if ldap.bind
            qatr = {
              base: Settings.ldap_auth.base,
              filter: Net::LDAP::Filter.eq(Settings.ldap_auth.login_name,account_name),
              attributes: LDAP_ATTRS,
              return_result: true
            }
            result = ldap.search(qatr).first
            unless result.nil?
              user = User.find_or_create_ldap_account(account_name, domain_name, password, result)
              unless user.nil?
                success!(user)
              else
                Rails.logger.error "Error LDAP Auth: can not found or create account"
                return fail(:invalid_login)
              end
            else
              # not found
              result = ldap.get_operation_result.inspect
              Rails.logger.error "Error LDAP Auth:" + result.inspect
              return fail(:invalid_login)
            end
          else
            result = ldap.get_operation_result.inspect
            Rails.logger.error "Error LDAP Auth:" + result.inspect
            return fail(:invalid_login)
          end
          
        end
      end

      def username
        params[:user][:login]
      end

      def password
        params[:user][:password]
      end
      
      def account_name
        str = username.match(/^(.+)@(.+)$/)
        str[1] rescue nil
      end
      
      def domain_name
        str = username.match(/^(.+)@(.+)$/)
        str[2] rescue nil
      end
    
    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)