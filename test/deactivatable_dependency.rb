class DeactivatableDependency < ActiveRecord::Base

  acts_as_deactivatable
  scope :with_scoped_status, where(:status => 1)

end
