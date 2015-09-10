require 'imap_client'
require 'test_helper'

class RendezvousHashTest < ActiveSupport::TestCase
  test "Hashing" do
    site_tags = ["site 1", "site 2", "site 3"]
    r = ImapClient::RendezvousHash.new
    r.site_tags = site_tags
    assert site_tags.include?(r.hash("A"))
    assert_equal r.hash("A"), r.hash("A")
    assert_not_equal r.hash("A"), r.hash("B")
  end
end
