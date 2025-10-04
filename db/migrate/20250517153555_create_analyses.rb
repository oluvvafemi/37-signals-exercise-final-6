class CreateAnalyses < ActiveRecord::Migration[8.0]
  def change
    create_table :analyses do |t|
      t.string :title
      t.integer :word_count
      t.string :status, default: "pending", null: false, index: true
      t.references :web_page, null: false, foreign_key: true
      t.text :table_of_contents
      t.text :top_word_frequencies

      t.timestamps
    end
  end
end
