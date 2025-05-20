class WebPage < ApplicationRecord
  has_one :analysis, dependent: :destroy
  after_create :create_analysis

  validates :url, presence: true, uniqueness: true
  validates :url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }

  def initiate_analysis
    AnalysisJob.perform_later(self.analysis)
  end

  scope :with_recently_completed_analysis, -> {
    joins(:analysis)
    .where(analysis: { status: :completed })
    .order("analysis.updated_at DESC")
    .limit(25)
  }

  private

  def create_analysis
    Analysis.create!(web_page: self)
  end
end
