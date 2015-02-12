class Spree::Admin::GoogleBaseSettingsController < Spree::Admin::BaseController
  helper 'spree/admin/google_base'
  
  def update
    params.each do |name, value|
      next unless Spree::GoogleBase::Config.has_preference? name
      Spree::GoogleBase::Config[name] = value
    end
    
    respond_to do |format|
      format.html {
        redirect_to edit_admin_google_base_settings_path
      }
    end
  end

end
