require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'activerecord'
require 'deactivatable'
require 'deactivatable_dependency'
require 'deactivatable_item'

class Test::Unit::TestCase
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")

  ActiveRecord::Schema.define(:version => 1) do
    create_table :deactivatable_items do |t|
      t.datetime :deactivated_at
    end    
  end
  
  ActiveRecord::Schema.define(:version => 1) do
    create_table :deactivatable_dependencies do |t|
      t.datetime :deactivated_at
      t.belongs_to :deactivatable_item
    end    
  end
  
end
