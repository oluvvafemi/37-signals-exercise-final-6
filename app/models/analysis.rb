class Analysis < ApplicationRecord
  belongs_to :web_page
  include Executable
end
