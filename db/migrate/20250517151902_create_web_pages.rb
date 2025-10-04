class CreateWebPages < ActiveRecord::Migration[8.0]
  def change
    create_table :web_pages do |t|
      t.string :url

      t.timestamps
    end
  end
end
