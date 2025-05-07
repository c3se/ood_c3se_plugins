Rails.application.config.after_initialize do
  Rails.logger.info 'Setup custom methods and routes for lmod plugin'

  class LmodController < ApplicationController
    def spider
      require 'json'
      module_json = Rails.cache.fetch("lmod_spider", expires_in: 15.minutes) do
        raw_json = `/usr/share/lmod/lmod/libexec/spider -o spider-json \
                    /apps/Common/fmodules/all /apps/Arch/fmodules/all/`

        JSON.parse(raw_json).transform_values {
          |val| val.map {
            |path, detail|
            detail.select {
              |key, value|
              ["provides", "Version", "Description"].include?(key)
            }
          }
        }
      end

      respond_to do |format|
        format.json { render json: module_json }
      end
    end

    def check
      modules = params[:modules]

      # sanity check
      modules.each do |mod|
        unless mod.match?(/^[a-zA-Z0-9_\-\.]+\/[a-zA-Z0-9_\-\.]+$/)
          raise "Invalid module: '#{mod}', will not attempt to load."
        end
      end


      stdout, stderr, status = Open3.capture3(
        "bash --login -c 'module load #{modules.join(' ')}'")

      if stderr.match(/Lmod has detected the following error:/)
        # only forward message if Lmod said something
        message = stderr.strip.gsub("\n", "<br>\n").gsub(
          "Lmod has detected the following error:") do |match|
          "<span style='color:#7a1a28;'><strong>#{match}</strong></span>"
        end
      else
        message = ''
      end

      render turbo_stream: turbo_stream.replace(
               "lmod-help-error",
               "<div id='lmod-help-error'>#{message}</div>")
    end
  end


  Rails.application.routes.append do
    get 'lmod_spider', to: 'lmod#spider'
    post 'lmod_check', to: 'lmod#check'
  end
end
