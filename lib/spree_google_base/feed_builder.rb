require 'net/ftp'
require 'csv'

module SpreeGoogleBase
  class FeedBuilder
    include Spree::Core::Engine.routes.url_helpers

    attr_reader :store, :domain, :title, :format

    def self.generate_and_transfer(format)
      raise "Invalid format specified! Supported formats: xml, txt" unless format == 'txt' or format == 'xml'
      self.builders.each do |builder|
        builder.generate_and_transfer_store(format)
      end
    end

    def self.generate_test_file(filename)
      exporter = new
      exporter.instance_variable_set("@filename", filename)
      format = filename.split('.')[-1]
      if format == "xml"
        File.open(exporter.path, "w") do |file|
          exporter.generate_xml file
        end
      elsif format == "txt"
        File.open(exporter.path, "w") do |file|
          file.write(exporter.generate_txt)
        end
      else
        raise "Invalid format specified! Supported formats: xml, txt"
      end
      exporter.path
    end

    def self.builders
      if defined?(Spree::Store)
        Spree::Store.all.map{ |store| self.new(:store => store) }
      else
        [self.new]
      end
    end

    def initialize(opts = {})
      raise "Please pass a public address as the second argument, or configure :public_path in Spree::GoogleBase::Config" unless
        opts[:store].present? or (opts[:path].present? or Spree::GoogleBase::Config[:public_domain])

      @store = opts[:store] if opts[:store].present?
      @title = @store ? @store.name : Spree::GoogleBase::Config[:store_name]

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

    def generate_and_transfer_store(format)
      @format = format
      delete_file_if_exists

      File.open(path, 'w') do |file|
        if @format == 'xml'
          generate_xml file
        else
          file.write(generate_txt)
        end
      end

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

    def generate_xml output
      xml = Builder::XmlMarkup.new(:target => output)
      xml.instruct!

      xml.rss(:version => '2.0', :"xmlns:g" => "http://base.google.com/ns/1.0") do
        xml.channel do
          build_meta(xml)

          ar_scope.find_each(:batch_size => 300) do |variant|
            build_variant_xml(xml, variant)
          end
        end
      end
    end

    def generate_txt
      csv_string = CSV.generate(col_sep: "\t") do |csv|
        # Header row
        csv << GOOGLE_BASE_ATTR_MAP.map { |row| row[0] } + ["link", "image_link", "additional_image_link"]
        # variants
        ar_scope.find_each(:batch_size => 300) do |variant|
          csv << build_variant_txt(variant)
        end
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
        xml.tag!('link', product_url(variant.slug, :host => domain))
        build_images_xml(xml, variant)

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
      attr_array << product_url(variant.slug, :host => domain)
      attr_array.concat(build_images_txt(variant))
      return attr_array
    end

    def build_images_xml(xml, variant)
      if Spree::GoogleBase::Config[:enable_additional_images]
        main_image, *more_images = variant.images
      else
        main_image = variant.images.first
      end

      return unless main_image
      xml.tag!('g:image_link', image_url(variant, main_image))

      if Spree::GoogleBase::Config[:enable_additional_images]
        more_images.each do |image|
          xml.tag!('g:additional_image_link', image_url(variant, image))
        end
      end
    end

    def build_images_txt(variant)
      images = []
      if Spree::GoogleBase::Config[:enable_additional_images]
        main_image, *more_images = variant.images
      else
        main_image = variant.images.first
      end

      return [] unless main_image
      images << image_url(variant, main_image)

      if Spree::GoogleBase::Config[:enable_additional_images]
        additional_images = []
        more_images.each do |image|
          additional_images << image_url(variant, image)
        end
        images << additional_images.join(',')
      end
      return images
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
