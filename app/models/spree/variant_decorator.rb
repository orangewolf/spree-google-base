module Spree
  Variant.class_eval do

    def self.google_base_scope
      where_sql = '
        is_master = false
        or product_id in (
          select p.id
          from spree_products p
          join spree_variants v on v.product_id = p.id
          group by p.id
          having count(v.id) <= 1
        )'
      Spree::Variant.includes(product: [:taxons, master: :images]).where(where_sql)
    end

    def google_base_description
      description
    end

    def google_base_condition
      'new'
    end

    def google_base_availability
      if self.total_count_on_hand > 0
        'in stock'
      else
        'out of stock'
      end
    end

    def google_base_image_size
      :large
    end

    def google_base_brand
      # Taken from github.com/romul/spree-solr-search
      # app/models/spree/product_decorator.rb
      #
      pp = Spree::ProductProperty.joins(:property)
                                 .where(:product_id => self.product_id)
                                 .where(:spree_properties => {:name => 'Brand'})
                                 .first

      pp ? pp.value : nil
    end

    def google_base_product_type
      return google_base_taxon_type unless Spree::GoogleBase::Config[:enable_taxon_mapping]

      product_type = ''
      priority = -1000
      product.taxons.each do |taxon|
        if taxon.taxon_map && taxon.taxon_map.priority > priority
          priority = taxon.taxon_map.priority
          product_type = taxon.taxon_map.product_type
        end
      end
      product_type
    end

    def google_base_taxon_type
      return unless product.taxons.any?

      product.taxons[0].self_and_ancestors.map(&:name).join(" > ")
    end

    def total_count_on_hand
      stock_items.sum(:count_on_hand)
    end
  end
end
