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

    def google_base_image
      images.first || product.images.first
    end

    def google_base_image_link
      if image = google_base_image
        image_link = image.attachment.url(google_base_image_size)
        image_link = Spree::GoogleBase::Config[:public_domain] + image_link unless image_link.starts_with?("http")
        image_link
      else
        nil
      end
    end

    def google_base_image_size
      :large
    end

    def google_base_brand
      # Taken from github.com/romul/spree-solr-search
      # app/models/spree/product_decorator.rb
      #
      # pp = Spree::ProductProperty.joins(:property)
      #                            .where(:product_id => self.id)
      #                            .where(:spree_properties => {:name => 'brand'})
      #                            .first
      #
      # pp ? pp.value : nil
      product.property('brand')
    end

    def google_base_product_category
      return google_base_product_type unless Spree::GoogleBase::Config[:enable_taxon_mapping]

      product_category = ''
      priority = -1000
      product.taxons.each do |taxon|
        if !taxon.taxonomy.no_google_base && taxon.taxon_map && taxon.taxon_map.priority > priority && taxon.taxon_map.product_type.present?
          priority = taxon.taxon_map.priority
          product_category = taxon.taxon_map.product_type
        end
      end
      product_category
    end

    def google_base_product_type
      product.taxons.each do |taxon|
        if !taxon.taxonomy.no_google_base
          return taxon.self_and_ancestors.map(&:name).join(" > ")
        end
      end
    end

    def total_count_on_hand
      stock_items.sum(:count_on_hand)
    end

    def google_base_item_group_id
      product.id if product.has_variants?
    end

    def google_base_age_group
      age = product.property('age_group')
      age ||= product.property('age')
      age ||= ''
      age = age.downcase
      case age
        when "youth" then 'kids'
        else age
      end
    end

    def google_base_gender
      gender = product.property('gender')
      gender ||= ''
      gender = gender.downcase
      case gender
        when "men's" then 'male'
        when "women's" then 'female'
        else gender
      end
    end

    def google_base_color
      option_values.each do |ov|
        return ov.presentation if ov.option_type.name =~ /color/i
      end
      product.property('color')
    end

    def google_base_size
      option_values.each do |ov|
        return ov.presentation if ov.option_type.name =~ /(length|size)/i
      end
      product.property('size')
    end
  end
end
