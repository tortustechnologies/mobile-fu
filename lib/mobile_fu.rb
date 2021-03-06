module ActionController
  module MobileFu
    # These are various strings that can be found in mobile devices.  Please feel free
    # to add on to this list.
    MOBILE_USER_AGENTS =  'palm|blackberry|nokia|phone|midp|mobi|symbian|chtml|ericsson|minimo|' +
                          'audiovox|motorola|samsung|telit|upg1|windows ce|ucweb|astel|plucker|' +
                          'x320|x240|j2me|sgh|portable|sprint|docomo|kddi|softbank|android|mmp|' +
                          'pdxgw|netfront|xiino|vodafone|portalmmm|sagem|mot-|sie-|ipod|up\\.b|' +
                          'webos|amoi|novarra|cdm|alcatel|pocket|iphone|mobileexplorer|' +
                          'mobile'
    
    def self.included(base)
      base.extend(ClassMethods)
    end
    
    module ClassMethods

      # Add this to one of your controllers to use MobileFu.
      #
      #    class ApplicationController < ActionController::Base 
      #      has_mobile_fu
      #    end
      #
      # You can also force mobile mode by setting the option :test_mode
      # to true:
      #
      #    class ApplicationController < ActionController::Base 
      #      has_mobile_fu(:test_mode => true)
      #    end
      #
      # Tell mobile fu to automatically set session[:mobile_view] based on
      # params[:format] by enabling the option :setup_session.
      #
      #    has_mobile_fu(:setup_session => true)
      #
      # Then you may switch your session between the two modes by passing
      # the query string "format=mobile" or "format=html".
        
      def has_mobile_fu(options = {})
        options.reverse_merge! :test_mode => false, :setup_session => false

        include ActionController::MobileFu::InstanceMethods

        if options[:setup_session]
          before_filter :set_mobile_session
        end

        if options[:test_mode]
          before_filter :force_mobile_format
        else
          before_filter :set_mobile_format
        end

        helper_method :is_mobile_device?
        helper_method :in_mobile_view?
        helper_method :is_device?
      end
      
      def is_mobile_device?
        @@is_mobile_device
      end

      def in_mobile_view?
        @@in_mobile_view
      end

      def is_device?(type)
        @@is_device
      end
    end
    
    module InstanceMethods
      
      # Forces the request format to be :mobile
      
      def force_mobile_format
        request.format = :mobile
        session[:mobile_view] = true if session[:mobile_view].nil?
      end

      # Change the :mobile_view session var based on params[:format].
      #
      # To make mobile-fu use this before_filter, call has_mobile_fu
      # with the option :use_session => true

      def set_mobile_session
        Rails.logger.debug "session[:mobile_view] is: #{session[:mobile_view]}"
        if params[:format]
          if params[:format] == 'html'
            session[:mobile_view] = false
          elsif params[:format] == 'mobile'
            session[:mobile_view] = true
          end
          Rails.logger.debug "session[:mobile_view] changed to: #{session[:mobile_view]}"
        end
      end
      
      # Determines the request format based on whether the device is mobile or if
      # the user has opted to use either the 'Standard' view or 'Mobile' view.
      
      def set_mobile_format
        unless request.xhr?
          if is_mobile_device?
            request.format = session[:mobile_view] == false ? :html : :mobile
            session[:mobile_view] = true if session[:mobile_view].nil?
          else
            request.format = :mobile if session[:mobile_view]
          end
        end
      end
      
      # Returns either true or false depending on whether or not the format of the
      # request is either :mobile or not.
      
      def in_mobile_view?
        request.format.to_sym == :mobile
      end
      
      # Returns either true or false depending on whether or not the user agent of
      # the device making the request is matched to a device in our regex.
      
      def is_mobile_device?
        request.user_agent.to_s.downcase =~ Regexp.new(ActionController::MobileFu::MOBILE_USER_AGENTS)
      end

      # Can check for a specific user agent
      # e.g., is_device?('iphone') or is_device?('mobileexplorer')
      
      def is_device?(type)
        request.user_agent.to_s.downcase.include?(type.to_s.downcase)
      end
    end
    
  end
  
end

ActionController::Base.send(:include, ActionController::MobileFu)