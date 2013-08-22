module ActiveRecord
  module Acts
    module Deactivatable

      def self.included(base) #:nodoc:
        base.extend(Definition)
      end

      module Definition
        # Define the calling class as being deactivatable.
        # A call to this will set the default scope of the object to look for deactivated_at = nil.
        # Options
        #   :dependencies - A list of symbols specifying any associations that are also deactivatable.  (The dependent association must separately be defined with acts_as_deactivatable).
        #   :auto_configure_dependencies - true or false (default).  If set to true, any association defined as :dependent => :destroy or :dependent => :delete_all will be added to the list of dependencies to deactivate.  NOTE: This call must occur after your dependency definitions to work properly.
        #
        def acts_as_deactivatable(options={})
          include ActiveRecord::Acts::Deactivatable::InstanceMethods

          default_scope where(:deactivated_at => nil)

          instance_eval <<-EOV
            def deactivatable_options
              options = #{options}
              return {} unless options
              if options[:auto_configure_dependencies] == true
                options[:dependencies] ||= []
                options[:dependencies] += setup_autoconfigured_dependencies
              end
              options
            end
          EOV
        end

        # Yields to a block, executing that block after removing the deactivated_at scope.
        #
        def with_deactivated_objects_scope
          remove_deactivated_objects_scope do
            with_scope(:find => where("`#{self.table_name}`.`deactivated_at` IS NOT NULL")) do
              yield
            end
          end
        end

        # Remove any scope related to deactivated_at and yield.
        #
        def remove_deactivated_objects_scope
          unscoped.where(scoped_methods_without_deactivated_at_scope)
        end

        private
        # Scan the reflection associations defined on the current class,
        # if the :dependent option is set to :destroy or :delete_all then add that reflection to the list of dependencies to be deactivated.
        #
        def setup_autoconfigured_dependencies
          self.reflections.each_value.inject([]) do |dependencies, reflection|
            dependencies << reflection.name if [:destroy, :delete_all].include?(reflection.options[:dependent])
            dependencies
          end
        end

        def scoped_methods_without_deactivated_at_scope
          remove_deactivated_attrs(scope_attributes)
        end

        def remove_deactivated_attrs(attrs)
          attrs.reject do |k,v|
            remove_deactivated_attrs(v) if v.is_a?(Hash)
            k == "deactivated_at"
          end
        end
      end

      module InstanceMethods
        # Deactivate this object, and any associated objects as specified at definition time.
        #
        def deactivate!
          with_transaction do
            self.deactivated_at = Time.now
            deactivate_dependencies
            self.save(:validation => false)
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

        def deactivated?
          deactivated_at?
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
        # Execution must be wrapped in the dependency's with_deactivated_objects_scope for activate! to work.
        #
        def execute_on_dependency(dependency_name, method)
          self.class.reflections[dependency_name].klass.send(:with_exclusive_scope) do
            if dependency = self.__send__(dependency_name)
              dependency.respond_to?(:map) ? dependency.map(&method) : dependency.__send__(method)
            end
          end
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