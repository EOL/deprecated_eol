Migration Model
===============

Ever wanted to use models in your migration?  Everybody told you not to, but you did anyway.

Later on, your migrations started exploding because of changes you made to your model.  Major FAIL.

Now, your can safely use your models in migrations without getting yelled at!  YAY!


FAIL Example
------------

    def self.up
      User.create :with => 'some stuff'  # FAIL!  Changing the User model may easily break this
    end


YAY OK Example
--------------

    def self.up
      mm(User).create :with => 'some stuff'  # YAY!  So long as the columns exist, you're good!
    end


How to install?
---------------

    $ ./script/plugin install git://github.com/remi/migration_model.git


Usage
-----

    safe_user_model = migration_model(User)
    safe_user_model.delete_all
    safe_user_model.create :some => 'stuff'

    safe_user_model = mm(User) # mm is a shortcut to migration_model
    bob = safe_user_model.create :name => 'bob'
    mm(User).find_all_by_name 'bob'

You can use your 'migration model' just like you use the real one, EXCEPT:

  * the migration model has NO associations
  * the migration model has NO validations
  * the migration model has NONE of your model's custom logic

When you use models in your migrations, you typically just want to use the 
convenience of ActiveRecord to move around data.

*IF* for some reason you need to add custom logic to your migration models:

    safe_user = mm(User) do

      # anything that works in a normal model will work in here

      has_many :comments

      named_scope :active, :conditions => ['active = ?', true]

      def something_custom
        'w00t'
      end
    end

    safe_user.comments
