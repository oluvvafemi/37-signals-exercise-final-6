module WebPage::Analyzable
  extend ActiveSupport::Concern

  included do
    has_one :analysis, dependent: :destroy
    after_create :create_analysis

    scope :most_recently_analyzed, -> {
      joins(:analysis)
      .where(analysis: { status: :completed })
      .order("analysis.updated_at DESC")
      .limit(25)
    }
  end

  def initiate_analysis
    AnalysisJob.perform_later(self.analysis)
  end

  private

  def create_analysis
    Analysis.create!(web_page: self)
  end
end
