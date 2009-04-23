Warden::Strategies.add(:pass_without_user) do
  def authenticate!
    request.env['warden.spec.strategies'] ||= []
    request.env['warden.spec.strategies'] << :pass_without_user
    success!(nil)
  end
end
