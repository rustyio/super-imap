require 'test_helper'

class Api::V1::UsersControllerTest < ActionController::TestCase
  setup do
    @partner = Partner.first
    @connection = @partner.connections.first
    @code = @connection.imap_provider_code
    @user = @connection.users.first
    @data = {
      :api_key => @partner.api_key,
      :connection_imap_provider_code => @code
    }
  end

  test "index" do
    get(:index, @data)
    assert_response :success
  end

  test "create" do
    post(:create, @data.merge(:tag => "TAG", :email => "EMAIL",
                              :login_username => "LOGIN_USERNAME",
                              :login_password => "LOGIN_PASSWORD"))
    assert_response :success

    user = User.find_by_tag("TAG")
    assert_equal "LOGIN_USERNAME", user.login_username
    assert_equal "LOGIN_PASSWORD", user.login_password_secure
  end

  test "create without tag and email" do
    post(:create, @data)
    assert_response :bad_request
  end

  test "update" do
    post(:update, @data.merge(:tag => @user.tag, :login_username => "NEW_USERNAME"))
    assert_response :success
    assert "NEW_USERNAME", @user.reload.login_username
  end

  test "show" do
    get(:show, @data.merge(:tag => @user.tag))
    assert_response :success
  end

  test "destroy" do
    delete(:destroy, @data.merge(:tag => @user.tag))
    assert_response :success
    assert @user.reload.archived
  end
end
