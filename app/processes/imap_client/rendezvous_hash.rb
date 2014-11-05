# http://en.wikipedia.org/wiki/Rendezvous_hashing
class ImapClient::RendezvousHash
  attr_accessor :site_tags

  def initialize(site_tags)
    self.site_tags = site_tags
  end

  # Return the number of sites.
  def size
    return site_tags.length
  end

  # Return the highest priority item.
  def hash(object_tag)
    priority = site_tags.map do |site_tag|
      h = Digest::MD5.hexdigest("#{site_tag} - #{object_tag}")
      [h, site_tag]
    end.sort

    if priority.length > 0
      priority[0][1]
    end
  end
end
