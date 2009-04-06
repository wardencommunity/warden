Rack::Auth::Strategies.add(:pass) do
  def authenticate!
    request.env['rack.auth.spec.strategies'] ||= []
    request.env['rack.auth.spec.strategies'] << :pass
    success!("Valid User")
  end
end
