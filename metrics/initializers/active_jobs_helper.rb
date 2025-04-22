# extends the active jobs helper to allow extra metrics

Rails.application.config.after_initialize do
  Rails.logger.info 'Extending ActiveJobsHelper ...'

  # originally defined in: ondemand/apps/dashboard/app/helpers/active_jobs_helper.rb
  module ActiveJobsHelper
    def build_grafana_link(cluster, start_seconds, report_type, node_num, jobid = nil)
      c = OODClusters[cluster]
      grafana_uri = nil
      if c && c.custom_allow?(:grafana)
        server = c.custom_config(:grafana)
        cluster = server.fetch(:cluster_override, cluster)
        query_params = {
          orgId: server[:orgId],
          theme: server[:theme] || 'light',
          from: "#{start_seconds}000",
          to: 'now',
          "var-#{server[:labels]['cluster']}": cluster,
          "var-#{server[:labels]['host']}": node_num.split('.')[0],
        }
        if ['cpu','memory','gpu','gpu-power','vram'].include?(report_type)
          url_base = 'd-solo'
          query_params[:panelId] = server[:dashboard]['panels'][report_type]
        else
          url_base = 'd'
        end
        if jobid
          jobid = jobid.split('.')[0]
          query_params["var-#{server[:labels]['jobid']}"] = jobid unless server[:labels]['jobid'].nil?
        end
        uri = Addressable::Template.new("#{server[:host]}{/segments*}/{?query*}")
        grafana_uri = uri.expand({
                                   'segments' => [url_base, server[:dashboard]['uid'], server[:dashboard]['name']],
                                   'query'    => query_params,
                                 }).to_s
      end
      grafana_uri
    rescue StandardError => e
      puts "ERROR: #{e}"
      nil
    end
  end
end
