class Patient < ApplicationRecord
  enum :administrative_gender, %i[male female other unknown]

  before_create do
    self.uuid = SecureRandom.uuid
  end
end
