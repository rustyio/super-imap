require 'test_helper'

class Api::V1::ConnectionsControllerTest < ActionController::TestCase
  setup do
    @partner = Partner.first
    @connection = @partner.connections.first
  end

  test "index" do
    get(:index, :api_key => @partner.api_key)
  end

  test "get" do
    get(:show, :api_key => @partner.api_key, :auth_mechanism => @connection.auth_mechanism)
  end
end
