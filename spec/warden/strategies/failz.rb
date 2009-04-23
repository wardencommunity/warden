Warden::Strategies.add(:failz) do
  
  def authenticate!
    request.env['warden.spec.strategies'] ||= []
    request.env['warden.spec.strategies'] << :failz
    fail!("You Fail!")
  end
  
end
