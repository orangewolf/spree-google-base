class AddNoGoogleBaseToSpreeTaxonomy < ActiveRecord::Migration
  def up
    add_column :spree_taxonomies, :no_google_base, :boolean, default: false
    Spree::Taxonomies.reset_column_information
    Spree::Taxonomies.update_all(no_google_base: false)
  end

  def down
    remove_column :spree_taxonomies, :no_google_base
  end
end
