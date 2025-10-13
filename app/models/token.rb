class Token < ApplicationRecord
  validates :access_token, presence: true
  validates :expires_at, presence: true
  
  scope :netsuite, -> { where(provider: 'netsuite') }
  scope :valid, -> { where('expires_at > ?', Time.current) }
  
  def expired?
    expires_at < Time.current
  end
  
  def expires_in_seconds
    return 0 if expired?
    (expires_at - Time.current).to_i
  end
  
  def self.netsuite_token
    netsuite.valid.first
  end
  
  def self.update_netsuite_token(access_token:, refresh_token: nil, expires_in: nil)
    token = netsuite.first_or_initialize
    
    token.access_token = access_token
    token.refresh_token = refresh_token if refresh_token
    token.expires_in = expires_in.to_s if expires_in
    token.expires_at = Time.current + expires_in.to_i.seconds if expires_in
    token.provider = 'netsuite'
    
    token.save!
    token
  end
end
