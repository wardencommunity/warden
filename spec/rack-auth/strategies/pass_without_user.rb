Rack::Auth::Strategies.add(:pass_without_user) do
  def authenticate!
    request.env['rack.auth.spec.strategies'] ||= []
    request.env['rack.auth.spec.strategies'] << :pass_without_user
    success!(nil)
  end
end
