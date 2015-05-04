module Spree
  Variant.class_eval do

    def self.google_base_scope
      where_sql = '
        is_master = ?
        or product_id in (
          select p.id
          from spree_products p
          join spree_variants v on v.product_id = p.id
          group by p.id
          having count(v.id) <= 1
        )'
      Spree::Variant.includes(product: [:taxons, master: :images]).where(where_sql, false)
    end

    def google_base_description
      description
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
      # Taken from github.com/romul/spree-solr-search
      # app/models/spree/product_decorator.rb
      #
      pp = Spree::ProductProperty.joins(:property)
                                 .where(:product_id => self.id)
                                 .where(:spree_properties => {:name => 'brand'})
                                 .first

      pp ? pp.value : nil
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
        if taxon.root.name != 'Brand' and taxon.root.name != 'Tags'
          return taxon.self_and_ancestors.map(&:name).join(" > ")
        end
      end
      ''
    end

    def total_count_on_hand
      stock_items.sum(:count_on_hand)
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
