Rack::Auth::Strategies.add(:pass_without_user) do
  def authenticate!
    request.env['auth.spec.strategies'] ||= []
    request.env['auth.spec.strategies'] << :pass_without_user
    success!(nil)
  end
end
