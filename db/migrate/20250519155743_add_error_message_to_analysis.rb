class AddErrorMessageToAnalysis < ActiveRecord::Migration[8.0]
  def change
    add_column :analyses, :error_message, :text
  end
end
