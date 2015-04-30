require 'net/ftp'
require 'csv'

module SpreeGoogleBase
  class FeedBuilder
    include Spree::Core::Engine.routes.url_helpers

    GOOGLE_BASE_ADDITIONAL_ATTRS = %w[link image_link]
    GOOGLE_BASE_ADDITIONAL_ATTRS <<  "additional_image_link" if Spree::GoogleBase::Config[:enable_additional_images]

    attr_reader :store, :domain, :title, :format

    def self.generate_and_transfer(format)
      raise "Invalid format specified! Supported formats: xml, txt" unless %w[txt xml].include? format
      self.builders(format).each do |builder|
        builder.generate_and_transfer_store
      end
    end

    def self.generate_test_file(format)
      raise "Invalid format specified! Supported formats: xml, txt" unless %w[txt xml].include? format
      exporter = new(format: format)
      exporter.generate_file
    end

    def self.builders(format)
      if defined?(Spree::Store)
        Spree::Store.all.map{ |store| self.new(store: store, format: format) }
      else
        [self.new(format: format)]
      end
    end

    def initialize(opts = {})
      raise "Please pass a public address as the second argument, or configure :public_path in Spree::GoogleBase::Config" unless
        opts[:store].present? or (opts[:path].present? or Spree::GoogleBase::Config[:public_domain])

      @store = opts[:store] if opts[:store].present?
      @title = @store ? @store.name : Spree::GoogleBase::Config[:store_name]
      @format = opts[:format] if opts[:format].present?

      @domain = @store ? @store.domains.match(/[\w\.]+/).to_s : opts[:path]
      @domain ||= Spree::GoogleBase::Config[:public_domain]
      @domain = "http://" + @domain unless @domain.starts_with?("http")
    end

    def ar_scope
      if @store
        Spree::Variant.by_store(@store).google_base_scope
      else
        Spree::Variant.google_base_scope
      end
    end

    def generate_and_transfer_store
      delete_file_if_exists
      generate_file
      transfer_file
      cleanup_file
    end

    def path
      file_path = Rails.root.join('tmp')
      if defined?(Apartment)
        file_path = file_path.join(Apartment::Tenant.current_tenant)
        FileUtils.mkdir_p(file_path)
      end
      file_path.join(filename)
    end

    def filename
      @filename ||= "google_base_v#{@store.try(:code)}.#{@format}"
    end

    def delete_file_if_exists
      File.delete(path) if File.exists?(path)
    end

    def generate_file
      File.open(path, "w") do |file|
        case
        when @format == "xml" then generate_xml file
        when @format == "txt" then generate_txt file
        end
      end
      path
    end

    def generate_xml(output)
      xml = Builder::XmlMarkup.new(:target => output)
      xml.instruct!

      xml.rss(:version => '2.0', :"xmlns:g" => "http://base.google.com/ns/1.0") do
        xml.channel do
          build_meta(xml)

          ar_scope.each do |variant|
            build_variant_xml(xml, variant)
          end
        end
      end
    end

    def generate_txt(output)
      csv = CSV.new(output, col_sep: "\t")

      # Header row
      csv << GOOGLE_BASE_ATTR_MAP.map { |row| row[0] } + GOOGLE_BASE_ADDITIONAL_ATTRS

      # variants
      ar_scope.each do |variant|
        csv << build_variant_txt(variant)
      end
    end

    def transfer_file
      raise "Please configure your Google Base :ftp_username and :ftp_password by configuring Spree::GoogleBase::Config" unless
        Spree::GoogleBase::Config[:ftp_username] and Spree::GoogleBase::Config[:ftp_password]

      ftp = Net::FTP.new(Spree::GoogleBase::Config[:ftp_server])
      ftp.passive = true
      ftp.login(Spree::GoogleBase::Config[:ftp_username], Spree::GoogleBase::Config[:ftp_password])
      ftp.chdir(Spree::GoogleBase::Config[:ftp_directory])
      ftp.put(path, filename)
      ftp.quit
    end

    def cleanup_file
      File.delete(path)
    end

    def build_variant_xml(xml, variant)
      xml.item do
        GOOGLE_BASE_ADDITIONAL_ATTRS.each do |attribute|
          case
          when attribute == "link" then xml.tag!('link', product_url(variant.slug, :host => domain))
          when attribute == "image_link" then build_image_xml(xml, variant)
          when attribute == "additional_image_link" then build_additional_images_xml(xml, variant)
          end
        end

        GOOGLE_BASE_ATTR_MAP.each do |k, v|
          value = variant.send(v)
          xml.tag!(k, value.to_s) if value.present?
        end
      end
    end

    def build_variant_txt(variant)
      attr_array = []
      GOOGLE_BASE_ATTR_MAP.each do |k, v|
        value = variant.send(v)
        attr_array << value
      end
      GOOGLE_BASE_ADDITIONAL_ATTRS.each do |attribute|
        case
        when attribute == "link" then attr_array << product_url(variant.slug, :host => domain)
        when attribute == "image_link" then attr_array << build_image_txt(variant)
        when attribute == "additional_image_link" then attr_array << bulid_additional_images_txt(variant)
        end
      end
      return attr_array
    end

    def build_image_xml(xml, variant)
      main_image = get_main_image(variant)

      return unless main_image
      xml.tag!('g:image_link', image_url(variant, main_image))

    end

    def build_additional_images_xml(xml, variant)
      more_images = get_additional_images(variant)

      return unless more_images
      more_images.each do |image|
        xml.tag!('g:additional_image_link', image_url(variant, image))
      end
    end

    def build_image_txt(variant)
      main_image = get_main_image(variant)

      return unless main_image
      image_url(variant, main_image)
    end

    def bulid_additional_images_txt(variant)
      more_images = get_additional_images(variant)

      return unless more_images
      images = []
      more_images.each do |image|
        images << image_url(variant, image)
      end
      images.join(',')
    end

    def get_main_image(variant)
      variant.images.first || variant.product.images.first
    end

    def get_additional_images(variant)
      variant.images[1..-1] || variant.product.images[1..-1]
    end

    def image_url(variant, image)
      base_url = image.attachment.url(variant.google_base_image_size)
      if Spree::Image.attachment_definitions[:attachment][:storage] != :s3
        base_url = "#{domain}#{base_url}"
      end

      base_url
    end

    def build_meta(xml)
      xml.title @title
      xml.link @domain
    end

  end
end
