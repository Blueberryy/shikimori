class RemoveIntClubPolicies < ActiveRecord::Migration
  def change
    remove_column :clubs, :join_policy, :integer
    remove_column :clubs, :comment_policy, :integer
  end
end
