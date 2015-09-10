# http://en.wikipedia.org/wiki/Rendezvous_hashing
class ImapClient::RendezvousHash
  attr_accessor :lock

  def initialize
    @site_tags = []
    @lock = Mutex.new
  end

  def site_tags=(site_tags)
    lock.synchronize do
      @site_tags = site_tags
    end
  end

  # Return the number of sites.
  def size
    lock.synchronize do
      return @site_tags.length
    end
  end

  # Return the highest priority item.
  def hash(object_tag)
    hashes = self.lock.synchronize do
      @site_tags.map do |site_tag|
        h = Digest::SHA1.hexdigest("#{site_tag} - #{object_tag}")
        [h, site_tag]
      end
    end

    priority = hashes.sort

    if priority.length > 0
      priority[0][1]
    end
  end
end
