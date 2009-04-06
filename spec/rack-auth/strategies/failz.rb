Rack::Auth::Strategies.add(:failz) do
  
  def authenticate!
    request.env['rack.auth.spec.strategies'] ||= []
    request.env['rack.auth.spec.strategies'] << :failz
    fail!("You Fail!")
  end
  
end
