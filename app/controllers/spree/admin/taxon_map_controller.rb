module Spree
  module Admin
    class TaxonMapController < Spree::Admin::BaseController

      def index
        @taxons = Spree::Taxon.joins(:taxonomy).where({"spree_taxonomies.no_google_base" => false}).each do |taxon|
          if !taxon.taxon_map
            taxon_map = Spree::TaxonMap.new(:product_type => '', :taxon_id => taxon.id, :priority => 0)
            taxon_map.save
            taxon.taxon_map = taxon_map
          end
        end
      end

      def create
        Spree::TaxonMap.delete_all
        params[:tax_id].each do |k, v|
          taxon_map = Spree::TaxonMap.new(:product_type => v, :taxon_id => k, :priority => params[:priority][k].to_i || 0)
          taxon_map.save
        end
        if Spree::TaxonMap.count == params[:tax_id].size
          flash[:notice] = "Google Base taxons mapping saved successfully."
        end
        redirect_to admin_taxon_map_index_url
      end
    end
  end
end
