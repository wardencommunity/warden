# encoding: utf-8
Warden::Strategies.add(:fail_with_user) do
  def authenticate!
    request.env['warden.spec.strategies'] ||= []
    request.env['warden.spec.strategies'] << :fail_with_user
    self.user = 'Valid User'
    fail!
  end
end

