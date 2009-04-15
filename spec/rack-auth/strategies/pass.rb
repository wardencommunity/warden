Rack::Auth::Strategies.add(:pass) do
  def authenticate!
    request.env['auth.spec.strategies'] ||= []
    request.env['auth.spec.strategies'] << :pass
    success!("Valid User")
  end
end
