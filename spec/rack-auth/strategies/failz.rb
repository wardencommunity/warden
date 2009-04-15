Rack::Auth::Strategies.add(:failz) do
  
  def authenticate!
    request.env['auth.spec.strategies'] ||= []
    request.env['auth.spec.strategies'] << :failz
    fail!("You Fail!")
  end
  
end
