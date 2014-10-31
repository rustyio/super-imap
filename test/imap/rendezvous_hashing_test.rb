require 'test_helper'

class RendezvousHashingTest < ActiveSupport::TestCase
  test "Hashing" do
    site_tags = ["site 1", "site 2", "site 3"]
    r = RendezvousHashing.new(site_tags)
    assert site_tags.include?(r.hash("A"))
    assert_equal r.hash("A"), r.hash("A")
    assert_not_equal r.hash("A"), r.hash("B")
  end
end
