require 'acts-as-taggable-on'

class Spree::BlogEntry < ActiveRecord::Base
  acts_as_taggable_on :tags, :categories
  before_save :create_permalink
  before_save :set_published_at
  validates_presence_of :title
  validates_presence_of :body
  validates_presence_of :blog_entry_image

  default_scope { order("published_at DESC") }
  scope :visible, -> { where :visible => true }
  scope :recent, lambda { |max=5| visible.limit(max) }

  if Spree.user_class
    belongs_to :author, :class_name => Spree.user_class.to_s
  else
    belongs_to :author
  end

  has_one :blog_entry_image, :as => :viewable, :dependent => :destroy, :class_name => 'Spree::BlogEntryImage'
  accepts_nested_attributes_for :blog_entry_image, :reject_if => :all_blank

  alias_method :image, :blog_entry_image

  scope :by_tag, -> (tag_name) {
    return if tag_name.blank?
    tagged_with(tag_name, on: :tags)
  }
  scope :by_category, -> (category_name) {
    return if category_name.blank?
    tagged_with(category_name, on: :categories)
  }
  scope :by_author, -> (author) {
    return if author.blank?
    where(author_id: author)
  }
  scope :by_text, -> (text) {
    return if text.blank?
    where('title iLIKE :title OR body iLIKE :body',
      title: "%#{text}%", body: "%#{text}%")
  }

  scope :by_date, -> (date, period = nil) {
    return unless date
    if date.is_a?(Hash)
      keys = [:day, :month, :year].select {|key| date.include?(key) }
      period = keys.first.to_s
      date = DateTime.new(*keys.reverse.map {|key| date[key].to_i })
    end

    time = date.to_time.in_time_zone
    period = time.send("beginning_of_#{period}")..time.send("end_of_#{period}")
    where(:published_at => period )
  }

  # data for news archive widget, only visible entries
  def self.organize_blog_entries
    Hash.new { [] }.tap do |entries|
      years.each do |year|
        months_for(year).each do |month|
          date = DateTime.new(year, month)
          entries[year] << [date.strftime("%B"), self.visible.by_date(date, :month)]
        end
      end
    end
  end

  def entry_summary(chars=200)
    if summary.blank?
      "#{body[0...chars]}..."
    else
      summary
    end
  end

  def related(count = 5)
    @related = related_by_categories(count)
    return @related if @related.length == count
    @related += related_by_tags(count - @related.length)
    return @related if @related.length == count
    @related += self.class
      .recent(count - @related.length)
      .where.not(id: self.id)
  end

  def related_by_tags(count = 5)
    self.class
      .tagged_with(self.tag_list, on: :tags)
      .where.not(id: self.id)
      .limit(5)
  end

  def related_by_categories(count = 5)
    self.class
      .tagged_with(self.tag_list, on: :categories)
      .where.not(id: self.id)
      .limit(5)
  end

  private

  def self.years
    visible.map {|e| e.published_at.year }.uniq
  end

  def self.months_for(year)
    visible
      .where("EXTRACT(YEAR FROM published_at) = ?", year)
      .pluck("EXTRACT(MONTH FROM published_at)::int AS month")
      .uniq
  end

  def create_permalink
    self.permalink = title.to_url if permalink.blank?
  end

  def set_published_at
    self.published_at = Time.now if published_at.blank? && visible?
  end

  def validate
    # nicEdit field contains "<br>" when blank
    errors.add(:body, "can't be blank") if body =~ /^<br>$/
  end

end
