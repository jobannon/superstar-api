class CreateVotes < ActiveRecord::Migration[6.0]
  def change
    create_table :votes do |t|
      t.string :imdb_id
      t.integer :count

      t.timestamps
    end
  end
end
  