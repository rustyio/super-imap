require 'test_helper'

class Api::V1::ConnectionsControllerTest < ActionController::TestCase
  setup do
    @partner = Partner.first
    @connection = @partner.connections.first
  end

  test "index" do
    get(:index, :api_key => @partner.api_key)
  end

  test "create" do
    auth_mechanism = @connection.imap_provider.auth_mechanism
    @connection.delete
    post(:create, :api_key => @partner.api_key, :auth_mechanism => auth_mechanism)
  end

  test "create without auth_mechanism" do
    post(:create, :api_key => @partner.api_key)
  end

  test "update" do
    post(:update, :api_key => @partner.api_key)
  end

  test "show" do
    get(:show, :api_key => @partner.api_key, :auth_mechanism => @connection.auth_mechanism)
  end

  test "destroy" do
    delete(:destroy, :api_key => @partner.api_key, :auth_mechanism => @connection.auth_mechanism)
  end
end
