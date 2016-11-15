module Spree
  Taxonomy.class_eval do
    validates :no_google_base, inclusion: { in: [true, false] }
  end
end
