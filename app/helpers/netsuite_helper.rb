module NetsuiteHelper
  def netsuite_authenticated?
    Token.valid_netsuite_token&.access_token.present?
  end
end
