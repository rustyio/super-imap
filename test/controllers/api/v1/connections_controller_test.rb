require 'test_helper'

class Api::V1::ConnectionsControllerTest < ActionController::TestCase
  setup do
    @partner = Partner.first
    @connection = @partner.connections.first
  end

  test "index" do
    get(:index, :api_key => @partner.api_key)
    assert_response :success
  end

  test "create" do
    code = @connection.imap_provider_code
    @connection.delete
    post(:create, :api_key => @partner.api_key, :imap_provider_code => code)
    assert_response :success
  end

  test "create without code" do
    post(:create, :api_key => @partner.api_key)
    assert_response :not_found
  end

  test "update" do
    post(:update, :api_key => @partner.api_key, :imap_provider_code => @connection.imap_provider_code)
    assert_response :success
  end

  test "show" do
    get(:show, :api_key => @partner.api_key, :imap_provider_code => @connection.imap_provider_code)
    assert_response :success
  end

  test "destroy" do
    delete(:destroy, :api_key => @partner.api_key, :imap_provider_code => @connection.imap_provider_code)
    assert_response :success
  end
end
