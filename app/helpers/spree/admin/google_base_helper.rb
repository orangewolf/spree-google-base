module Spree
  module Admin
    module GoogleBaseHelper
      def setting_field(setting)
        type = Spree::GoogleBase::Config.preference_type(setting)
        res = ''
        res += label_tag(setting, Spree.t('google_base.' + setting.to_s) + ': ') + tag(:br) if type != :boolean
        res += preference_field_tag(setting, Spree::GoogleBase::Config[setting], :type => type)
        res += label_tag(setting, Spree.t('google_base.' + setting.to_s)) + tag(:br) if type == :boolean
        res.html_safe
      end
    end
  end
end
