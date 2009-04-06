Rack::Auth::Strategies.add(:password) do
  def authenticate!
    request.env['rack.auth.spec.strategies'] ||= []
    request.env['rack.auth.spec.strategies'] << :password
    if params["password"] || params["username"]
      params["password"] == "sekrit" && params["username"] == "fred" ?
        success!("Authenticated User") : fail!("Username or password is incorrect")
    else
      pass
    end
  end
end
