FactoryGirl.define do
  # factory :image, class: Spree::Image do
  #   attachment_content_type 'image/jpg'
  #   attachment_file_name 'something_filename.jpg'
  # end
  #
  sequence :custom_product_sequence do |n|
    "Product ##{n} - #{rand(9999)}"
  end

  factory :one_of_many_producs, class: Spree::Product do
    name { Factory.next(:product_sequence) }
    description { Faker::Lorem.paragraphs(rand(5)+1).join("\n") }

    price 19.99
    cost_price 17.00
    sku "ABC"
  end

  factory :taxon_map, class: Spree::TaxonMap do
    product_type 'Google Taxon Map'
    priority 0
  end

  # factory :store, class: Spree::Store do
  #   name 'My store'
  #   code 'my_store'
  #   domains 'www.example.com' # makes life simple, this is the default integration session domain
  # end
end

FactoryGirl.modify do
  factory :taxon do
    taxon_map
  end

  factory :taxonomy do
    no_google_base false
  end
end