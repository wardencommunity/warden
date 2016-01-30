# encoding: utf-8
require 'spec_helper'

describe Warden::Test::Mock do
  before{ $captures = [] }
  after{ Warden.test_reset! }

  it "should return a valid mocked warden" do
    user = "A User"
    login_as user

    expect(warden.class).to eq(Warden::Proxy)
    expect(warden.user).to eq(user)
  end
end
