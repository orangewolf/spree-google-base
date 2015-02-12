require 'net/ftp'

module SpreeGoogleBase
  class FeedBuilder
    include Spree::Core::Engine.routes.url_helpers
    
    attr_reader :store, :domain, :title, :description

    def self.generate
      self.builders.each do |builder|
        builder.generate_store
      end
    end

    def self.generate_and_transfer
      self.builders.each do |builder|
        builder.generate_and_transfer_store
      end
    end

    def self.generate_test_file(file_path)
      exporter = new

      File.open(file_path, "w") do |file|
        exporter.generate_xml file
      end
    end

    def self.builders
      if defined?(Spree::Store)
        Spree::Store.all.map{ |store| self.new(:store => store) }
      else
        [self.new]
      end
    end

    def initialize(opts = {})
      @title = Spree::GoogleBase::Config[:title]
      @domain = Spree::GoogleBase::Config[:public_domain]
      @description = Spree::GoogleBase::Config[:description]
      if opts[:store].present?
        @store = opts[:store]
        @title = @store.name unless @title.present?
        @domain = @store.domains.match(/[\w\.]+/).to_s unless @domain.present?
      else
        @title = Spree::Store.default.name unless @title.present?
        @domain = opts[:path].present? ? opts[:path] : Spree::Store.default.url unless @domain.present?
      end
      raise "Please pass a public address as the second argument, or configure :public_path in Spree::GoogleBase::Config" unless
          @domain.present?
    end
    
    def ar_scope
      if @store
        Spree::Product.by_store(@store).google_base_scope
      else
        Spree::Product.google_base_scope
      end
    end

    def generate_store
      delete_xml_if_exists

      File.open(path, 'w') do |file|
        generate_xml file
      end
    end

    def generate_and_transfer_store
      generate_store
      transfer_xml
      cleanup_xml
    end
    
    def path
      "#{::Rails.root}/tmp/#{filename}"
    end
    
    def filename
      "google_base_v#{@store.try(:code)}.xml"
    end

    def delete_xml_if_exists
      File.delete(path) if File.exists?(path)
    end

    def generate_xml output
      xml = Builder::XmlMarkup.new(:target => output)
      xml.instruct!

      xml.rss(:version => '2.0', :"xmlns:g" => "http://base.google.com/ns/1.0") do
        xml.channel do
          build_meta(xml)
          
          ar_scope.find_each(:batch_size => 300) do |product|
            build_product(xml, product)
          end
        end
      end
    end
    
    def transfer_xml
      raise "Please configure your Google Base :ftp_username and :ftp_password by configuring Spree::GoogleBase::Config" unless
        Spree::GoogleBase::Config[:ftp_username] and Spree::GoogleBase::Config[:ftp_password]
      
      ftp = Net::FTP.new('uploads.google.com')
      ftp.passive = true
      ftp.login(Spree::GoogleBase::Config[:ftp_username], Spree::GoogleBase::Config[:ftp_password])
      ftp.put(path, filename)
      ftp.quit
    end
    
    def cleanup_xml
      File.delete(path)
    end
    
    def build_product(xml, product)
      xml.item do
        xml.tag!('g:link', product_url(product.slug, :host => domain))
        build_images(xml, product)
        
        GOOGLE_BASE_ATTR_MAP.each do |k, v|
          value = product.send(v)
          xml.tag!(k, value.to_s) if value.present?
        end
      end
    end
    
    def build_images(xml, product)
      if Spree::GoogleBase::Config[:enable_additional_images]
        main_image, *more_images = product.master.images
      else
        main_image = product.master.images.first
      end

      return unless main_image
      xml.tag!('g:image_link', image_url(product, main_image))

      if Spree::GoogleBase::Config[:enable_additional_images]
        more_images.each do |image|
          xml.tag!('g:additional_image_link', image_url(product, image))
        end
      end
    end

    def image_url product, image
      base_url = image.attachment.url(product.google_base_image_size)
      base_url = "http://#{domain}#{base_url}" unless Spree::Image.attachment_definitions[:attachment][:storage] == :s3

      base_url
    end

    def build_meta(xml)
      xml.title title if title.present?
      xml.link url_for :controller => 'spree/home', :host => domain, :only_path => false
      xml.description description if description.present?
    end
    
  end
end
