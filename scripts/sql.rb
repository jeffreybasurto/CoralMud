require 'rubygems'
gem 'activerecord', '=2.3.2'
require 'active_record'

ActiveRecord::Base.establish_connection(
  :adapter => "mysql",
  :host => "localhost",
  :username => "root",
  :password => "plokij098",
  :database => "corundum")

class Account < ActiveRecord::Base
end

def test_acc_exists
  acc = Account.find_by_username("cpytel")
  puts acc.username
end

def delete_all_of_name n
  while (acc = Account.find_by_username("cpytel")) 
    acc.delete
  end
end

account = Account.new
account.username = "cpytel"
account.save

test_acc_exists
delete_all_of_name "cpytel"
