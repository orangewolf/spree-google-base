module Spree
  Variant.class_eval do
    scope :google_base_scope, -> { preload({:product => :taxons}, :images) }

    def google_base_title
      title = name
      title += " - #{options_text}" if option_values.exists?
      "#{title}".strip
    end

    def google_base_condition
      'new'
    end
    
    def google_base_availability
      total_on_hand > 0 ? 'in stock' : 'out of stock'
    end

    def google_base_image_size
      :large
    end

    def google_base_brand
      property_name = 'brand'
      product.property(property_name)
    end

    def google_base_product_category
      return google_base_product_type unless Spree::GoogleBase::Config[:enable_taxon_mapping]

      product_category = ''
      priority = -1000
      product.taxons.each do |taxon|
        if taxon.taxon_map && taxon.taxon_map.priority > priority
          priority = taxon.taxon_map.priority
          product_category = taxon.taxon_map.product_type
        end
      end
      product_category
    end

    def google_base_product_type
      product.taxons.each do |taxon|
        if taxon.root.name == 'Category'
          return taxon.self_and_ancestors.map(&:name).join(" > ")
        end
      end
      ''
    end

    def google_base_item_group_id
      product.id if product.has_variants?
    end

    def google_base_color
      option_values.each do |ov|
        return ov.presentation if ov.option_type.name =~ /color/i
      end
      ''
    end

    def google_base_size
      option_values.each do |ov|
        return ov.presentation if ov.option_type.name =~ /(length|size)/i
      end
      ''
    end
  end
end
