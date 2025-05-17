class WebPage < ApplicationRecord
  has_many :analyses, dependent: :destroy

  validates :url, presence: true, uniqueness: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }

  def initiate_analysis
    new_analysis = self.analyses.create!
    AnalysisJob.perform_later(new_analysis)
    new_analysis
  end
end
