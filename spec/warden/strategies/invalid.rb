Warden::Strategies.add(:invalid) do
  def valid?
    false
  end 
  
  def authenticate!; end
end