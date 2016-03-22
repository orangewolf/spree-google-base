require 'spec_helper'

describe SpreeGoogleBase::FeedBuilder do
  
  describe 'as class' do
    context '#builders should return an array for each store' do
      Spree::Store.delete_all
      FactoryGirl.build(:store, :code => 'first', :name => 'Goodies, LLC')
      Spree::GoogleBase::Config.set(:public_domain => 'http://mydomain.com')

      builders = SpreeGoogleBase::FeedBuilder.builders('xml')
      builders.size.should == 1
    end
  end

  describe 'as instance' do
    before{ @output = '' } 
    describe 'in general' do
      before(:each) do
        Spree::GoogleBase::Config.set(:public_domain => 'http://mydomain.com')
        Spree::GoogleBase::Config.set(:store_name => 'Froggies')
       
        @builder = SpreeGoogleBase::FeedBuilder.new
        @xml = Builder::XmlMarkup.new(:target => @output, :indent => 2, :margin => 1)
        @product = FactoryGirl.create(:product)
      end
      
      it 'should include products in the output' do
        @builder.build_variant_xml(@xml, @product.master)
        
        @output.should include(@product.name)
        @output.should include("products/#{@product.slug}")
        @output.should include(@product.price.to_s)
      end
      
      it 'should build the XML and not bomb' do
        @builder.generate_xml @output
        
        @output.should =~ /#{@product.name}/
        @output.should =~ /Froggies/
      end
      
    end

    describe 'w/out stores' do
      
      before(:each) do
        Spree::GoogleBase::Config.set(:public_domain => 'http://mydomain.com')
        Spree::GoogleBase::Config.set(:store_name => 'Froggies')
        
        @builder = SpreeGoogleBase::FeedBuilder.new
      end
      
      it "should know its path" do
        @builder.path.to_s.should == "#{::Rails.root}/tmp/google_base_v.xml.gz"
      end
      
      it "should initialize with the correct domain" do
        @builder.domain.should == Spree::GoogleBase::Config[:public_domain]
      end
      
      it "should initialize with the correct scope" do
        @builder.ar_scope.to_sql.should == Spree::Variant.google_base_scope.to_sql
      end
      
      it "should initialize with the correct title" do
        @builder.title.should == Spree::GoogleBase::Config[:store_name]
      end
      
      it 'should include configured meta' do
        @xml = Builder::XmlMarkup.new(:target => @output, :indent => 2, :margin => 1)
        @product = FactoryGirl.create(:product)
        
        @builder.build_meta(@xml)
        
        @output.should =~ /Froggies/
        @output.should =~ /http:\/\/mydomain.com/
      end
    end
  end
  
  describe 'when misconfigured' do
    it 'should raise an exception' do
      SpreeGoogleBase::FeedBuilder.new.should raise_error
    end
  end
  
end
