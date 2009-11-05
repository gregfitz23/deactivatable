class DeactivatableItem < ActiveRecord::Base

  has_many :deactivatable_dependencies

  acts_as_deactivatable :dependencies => [:deactivatable_dependencies]
  
end