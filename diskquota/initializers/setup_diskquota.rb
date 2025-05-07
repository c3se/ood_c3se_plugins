Rails.application.config.after_initialize do
  Rails.logger.info 'Add custom routes for quota'

  class DiskquotaController < ApplicationController
    def widget_list
      render turbo_stream: turbo_stream.replace(
               "diskquota-widget-list",
               partial: "widgets/diskquota_widget_list")
    end
  end

  Rails.application.routes.append do
    get 'diskquota_widget_list', to: 'diskquota#widget_list'
  end

end
