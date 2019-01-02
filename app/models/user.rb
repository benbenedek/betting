class User < ActiveRecord::Base
  has_secure_password

  validates :password, length: { minimum: 6 }

  def generate_token!
    self.auth_token = SecureRandom.urlsafe_base64
    self.save(validate: false)
  end
end
