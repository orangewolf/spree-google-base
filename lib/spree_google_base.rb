require 'spree_core'

module Spree
  module GoogleBase
    def self.config(&block)
      yield(Spree::GoogleBase::Config)
    end
  end
end

require 'spree_google_base/engine'

module Spree
  module PermittedAttributes

    @@taxonomy_attributes.concat [:no_google_base]

  end
end
