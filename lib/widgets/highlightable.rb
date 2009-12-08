module Widgets
  module Highlightable
    def self.included(base)
      # base.extend(ClassMethods)
      base.class_eval do
        include InstanceMethods
        attr_writer :highlights
        attr_writer :highlights_nots
      end
    end

    module InstanceMethods
      def highlights
        @highlights ||= []
        @highlights
      end
      def highlights_nots
        @highlights_nots ||= []
        @highlights_nots
      end

      # a rule can be:
      #  * a parameter hash eg: {:controller => 'main', :action => 'welcome'}
      #  * a string containing an URL eg: 'http://blog.seesaw.it'
      def highlights_on rule
        highlights << rule
      end

      def highlights_not_on rule
        highlights_nots << rule
      end

      # force the tab as highlighted
      def highlight!
        highlights_on proc { true }
      end

      # takes in input a Hash (usually params)
      # or a string/Proc that evaluates to true/false
      # it does ignore some params like 'only_path' etc..
      # we have to do this in order to support restful routes
      def highlighted? options={}
            matches_path?(highlights,      options) \
        && !matches_path?(highlights_nots, options)
      end

      # Adapted from highlighted? (vendor/plugins/rails-widgets/lib/widgets/highlightable.rb) to make it reusable anywhere in Rails
      # Returns true if actual_path matches any of the paths in expected_paths. (Pass :match => :all to require it to match ALL.)
      def matches_path?(expected_paths, actual_path = params, options = {})
        #puts "matches_path?(expected_paths=#{expected_paths.inspect}, actual_path=#{actual_path.inspect}, options=#{options.inspect})"
        options[:match] = :any
        actual_path = PathHash.new(actual_path)
        result = options[:match] == :any ? false : true

        expected_paths.each do |path|
          is_a_match = true
          if path.kind_of? String # do not path @TODO: should we evaluate the request URI for this?
            is_a_match &= false
          elsif path.kind_of? Proc # evaluate the proc
            a = path.call
            if (a.is_a?(TrueClass) || a.is_a?(FalseClass))
              is_a_match &= a
            else
              raise 'proc pathing rules must evaluate to TrueClass or FalseClass'
            end
          elsif path.kind_of? Hash
            h = PathHash.new(path)
            h.each_key do |key|
              # remove first slash from <tt>:controller</tt> key otherwise this could fail with urls such as {:controller => "/base"</tt>
              val = h[key].to_param.to_s.dup
              val.gsub!(/^\//,"") if key == :controller
              is_a_match &= (val==actual_path[key].to_s)
            end
          else
            raise 'pathing rules should be String, Proc or Hash'
          end

          if options[:match] == :any
            result |= is_a_match and break
          elsif options[:match] == :all
            result &= is_a_match or break
          else
            raise ArgumentError, "options[:match] must be either :any or :all but was #{options[:match]}"
          end
        end
        #puts "returning #{result}"
        return result
      end

      private

      # removes unwanted keys from a Hash
      # and returns a new hash
      def clean_unwanted_keys(hash)
        ignored_keys = [:only_path, :use_route]
        hash.dup.delete_if{|key,value| ignored_keys.include?(key)}
      end

      def check_hash(param, param_name)
        raise "param '#{param_name}' should be a Hash but is #{param.inspect}" unless param.kind_of?(Hash)
        param
      end
    end
  end
end
