# http://en.wikipedia.org/wiki/Rendezvous_hashing
class RendezvousHashing
  attr_accessor :site_tags

  def initialize(site_tags)
    self.site_tags = site_tags
  end

  # Return the first
  def hash(object_tag)
    site_tags.map do |site_tag|
      h = Digest::MD5.hexdigest("#{site_tag} - #{object_tag}")
      [h, site_tag]
    end.sort.first[1]
  end
end
