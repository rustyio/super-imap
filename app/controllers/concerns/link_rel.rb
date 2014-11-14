module LinkRel
  extend ActiveSupport::Concern

  included do
    def self.link_rel(tag, url)
      @links ||= []
      @links << %(<#{url}; rel="#{tag}")
      headers['Link'] = @links.join(', ') if links.present?
    end
  end
end
