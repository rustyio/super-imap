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
    code = @connection.imap_provider.code
    @connection.delete
    post(:create, :api_key => @partner.api_key, :imap_provider_code => code)
  end

  test "create without code" do
    post(:create, :api_key => @partner.api_key)
  end

  test "update" do
    post(:update, :api_key => @partner.api_key)
  end

  test "show" do
    get(:show, :api_key => @partner.api_key, :imap_provider_code => @connection.code)
  end

  test "destroy" do
    delete(:destroy, :api_key => @partner.api_key, :imap_provider_code => @connection.code)
  end
end
