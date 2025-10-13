module ApplicationHelper
  def netsuite_authenticated?
    Token.netsuite_token&.access_token.present?
  end
end
