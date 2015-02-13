module SpreeGoogleBase
  class Engine < Rails::Engine
    engine_name 'spree_google_base'

    config.autoload_paths += %W( #{config.root}/lib )

    initializer "spree.google_base.environment", :before => :load_config_initializers do |app|
      Spree::GoogleBase::Config = Spree::GoogleBaseConfiguration.new
      
      # See http://support.google.com/merchants/bin/answer.py?hl=en&answer=188494#US for all other fields
      SpreeGoogleBase::FeedBuilder::GOOGLE_BASE_ATTR_MAP = [
        ['g:id', 'sku'],
        ['g:title', 'name'],
        ['g:description', 'description'],
        ['g:price', 'price'],
        ['g:condition', 'google_base_condition'],
        ['g:google_product_category', 'google_base_product_category'],
        ['g:product_type', 'google_base_product_type'],
        ['g:brand', 'google_base_brand'],
        ['g:quantity','total_on_hand'],
        ['g:availability', 'google_base_availability'],
        ['g:shipping_weight', 'weight'],
        ['g:item_group_id', 'google_base_item_group_id']
      ]
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
    end

    config.to_prepare &method(:activate).to_proc
    
  end
end
