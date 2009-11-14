require File.dirname(__FILE__) + '/../../spec_helper'

describe Warden::Serializers::Cookie do
  before(:each) do
    @env = env_with_params
    @cookie = Warden::Serializers::Cookie.new(@env)
  end

  def set_cookie!
    @env['HTTP_COOKIE'] = @cookie.response.headers['Set-Cookie']
  end

  def read_cookie
    cookie = @cookie.response.headers['Set-Cookie']
    cookie = cookie.first if cookie.is_a?(Array)
    cookie.split(";").first
  end

  it "should store data for the default scope" do
    @cookie.store("user", :default)
    read_cookie.should == "warden.user.default.key=user"
  end

  it "should check if a data is stored or not" do
    @cookie.should_not be_stored(:default)
    @cookie.store("user", :default)
    set_cookie!
    @cookie.should be_stored(:default)
  end

  it "should load an user from store" do
    @cookie.fetch(:default).should be_nil
    @cookie.store("user", :default)
    set_cookie!
    @cookie.fetch(:default).should == "user"
  end

  it "should store data based on the scope" do
    @cookie.store("user", :default)
    set_cookie!
    @cookie.fetch(:default).should == "user"
    @cookie.fetch(:another).should be_nil
  end

  it "should delete data from store" do
    @cookie.store("user", :default)
    set_cookie!
    @cookie.fetch(:default).should == "user"
    @cookie.delete(:default)
    read_cookie.should == "warden.user.default.key="
  end

  it "should delete information from store if user cannot be retrieved" do
    @cookie.store("user", :default)
    set_cookie!
    @cookie.instance_eval "def deserialize(key); nil; end" 
    @cookie.fetch(:default)
    read_cookie.should == "warden.user.default.key="
  end
end
