class Setting < ApplicationRecord
  validates :key, presence: true, uniqueness: true, length: { maximum: 255 }

  class << self
    # @example
    #   Setting[:anonymize] # => true
    # @param [#to_s] key
    # @return [Object]
    # @raises ActiveRecord::RecordNotFound
    def [](key)
      find_by!(key: key.to_s).value
    end

    # @example
    #   Setting[:anonymize] = false
    # @param [#to_s] key - must already exist
    # @param [Object] value - must be json serializable
    # @return [Object] value
    # @raises ActiveRecord::RecordNotFound, ActiveRecord::RecordNotSaved
    def []=(key, value)
      instance = find_by!(key: key.to_s)
      instance.update!(value: value)
      value
    end
  end
end
