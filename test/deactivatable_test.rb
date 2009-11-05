require 'test_helper'

class DeactivatableTest < Test::Unit::TestCase
  
  context "An inactive item, @item" do
    setup do
      @inactive_item = DeactivatableItem.new
      @inactive_item.deactivated_at = Time.now
      @inactive_item.save!
    end
    
    should "not be returned on find" do
      assert !DeactivatableItem.exists?(@inactive_item.id)
    end
    
    context "when activated" do
      setup do
        @inactive_item.activate!
      end
      
      should "be findable" do
        assert DeactivatableItem.exists?(@inactive_item.id)
      end
    end #when reactivated    
  end #An inactive item, @inactive_item
  
  context "An active item, @item" do
    setup do
      @item = DeactivatableItem.create!
    end

    should "have a null deactivated_at" do
      assert_nil @item.deactivated_at
    end
    
    context "when deactivated" do
      setup do
        @item.deactivate!
      end
      
      should "set deactivated_at" do
        assert_not_nil @item.deactivated_at
      end
      
      should "not be findable" do
        assert !DeactivatableItem.exists?(@item.id)
      end      
    end #when deactivated
    
    context "with dependencies, @dependencies" do
      setup do
        @dependencies = (0..5).map { DeactivatableDependency.new }
        @item.deactivatable_dependencies = @dependencies
      end

      context "on a call to deactivate!" do
        setup do
          @item.deactivate!
        end
        
        should "render dependency unfindable" do
          @dependencies.each { |dependency| assert !DeactivatableDependency.exists?(dependency.id) }
        end
        
        should "set deactivate on dependency post" do
          DeactivatableDependency.send(:with_exclusive_scope) do
            @dependencies.map(&:reload)
            @dependencies.each {|dependency| assert_not_nil(dependency.deactivated_at) }
          end
        end
        
        context "when reactivated" do
          setup do
            @item.activate!
          end
          
          should "reactivate all dependencies" do
            @dependencies.each { |dependency| assert(DeactivatableDependency.exists?(dependency.id)) }
          end
        end #when reactivated
        
      end #on a call to deactivate!
    end #with dependencies, @dependencies
  end #An active item, @item

end
