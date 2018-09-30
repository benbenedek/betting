class League < ActiveRecord::Base
  has_many :fixtures

  def pretty_name
    "#{self.name} - #{self.season}"
  end
end
