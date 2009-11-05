module ActiveRecord
  module Acts
    module Deactivatable
    
      def self.append_features(base) #:nodoc:
        super
        base.extend(Definition)  
      end
      
      module Definition
        # Define the calling class as being deactivatable.  
        # A call to this will set the default scope of the object to look for deactivated_at = nil.
        # Options
        #   *:dependencies* => A list of symbols specifying any associations that are also deactivatable.  (This associations must separately be defined with acts_as_deactivatable).
        #
        def acts_as_deactivatable(options={})
          extend ActiveRecord::Acts::Deactivatable::ClassMethods          
          include ActiveRecord::Acts::Deactivatable::InstanceMethods
                    
          default_scope :conditions => {:deactivated_at => nil}
          
          @deactivatable_options = options
        end
        
      end
      
      module ClassMethods
        
        def deactivatable_options
          @deactivatable_options || {}
        end
        
        def deactivated_dependencies
          @deactivated_dependencies ||= []
        end
      end
   
      module InstanceMethods
        
        # Deactivate this object, and any associated objects as specified at definition time.
        #
        def deactivate!
          with_transaction do
            self.deactivated_at = Time.now            
            deactivate_dependencies
            self.save!
          end
        end
        
        # Activate this object, and any associated objects as specified at definition time.
        #
        def activate!
          with_transaction do
            self.deactivated_at = nil
            activate_dependencies
            self.save!            
          end
        end
                
        private
        # Iterate the list of associated objects that need to be deactivated, and deactivate each of them.
        #
        def deactivate_dependencies
          traverse_dependencies(:deactivate!)
        end

        # Iterate the list of associated objects that need to be activated, and activate each of them.
        #
        def activate_dependencies
          traverse_dependencies(:activate!)
        end
        
        # Traverse the list of dependencies, executing *method* on each of them.
        #
        def traverse_dependencies(method)
          if dependencies = self.class.deactivatable_options[:dependencies]
            dependencies.each { |dependency_name| execute_on_dependency(dependency_name, method) }
          end          
        end
        
        # Find the dependency indicated by *dependency_name* and execute *method* on it.
        #
        def execute_on_dependency(dependency_name, method)
          dependency = self.__send__(dependency_name)
          dependency.respond_to?(:map) ? dependency.map(&method) : dependency.__send__(method)
        end
        
        def with_transaction
          self.class.transaction do
            yield
          end
        end
        
      end
    end
  end
end

ActiveRecord::Base.class_eval do
  include ActiveRecord::Acts::Deactivatable
end