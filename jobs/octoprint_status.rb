#octoprint_status.rb
#
require 'net/http'
require 'openssl'
require 'yaml'
require 'json'
#require 'pry'
##############################################
# Load configuration
##############################################
octoConfDir = File.join(File.expand_path('..'), "conf.d")
octoConfMain = File.join(octoConfDir, "octoprint_defaults.yaml")
octoConfOverride = File.join(octoConfDir, "octoprint_override.yaml")
octoprint_config = YAML.load_file(octoConfMain)
if File.exists?(octoConfOverride)
#warn "OctoPrint: Merging Override"
  octoprint_config = octoprint_config.merge(YAML.load_file(octoConfOverride))
end

@api_port=octoprint_config['octo_server_api_port']
@api_key=octoprint_config['octo_server_api_key']
@api_ssl_enable=octoprint_config['octo_server_api_ssl']
@octo_server=octoprint_config['octo_server_fqdn']
@job_endpoint=octoprint_config['octo_server_api_job_endpoint']
@frequency=octoprint_config['octo_server_api_poll_interval']
#warn "OctoPrint: #{octoConfDir}"
#warn "OctoPrint: #{octoConfMain}"
#warn "OctoPrint: #{octoConfOverride}"
#warn "OctoPrint: #{@api_port}"
#warn "OctoPrint: #{@api_key}"
#warn "OctoPrint: #{@octo_server}"
#warn "OctoPrint: #{@api_ssl_enable}"
#warn "OctoPrint: #{@job_endpoint}"
def getOctoPrintStatus(server_fqdn,port,key,endpoint,ssl_enable)
  begin
#  warn "OctoPrint: getOctoPrintStatus: #{port}"
#  warn "OctoPrint: getOctoPrintStatus: #{key}"
#  warn "OctoPrint: getOctoPrintStatus: #{server_fqdn}"
#  warn "OctoPrint: getOctoPrintStatus: #{ssl_enable}"
#  warn "OctoPrint: getOctoPrintStatus: #{endpoint}"
    if ssl_enable
      _proto='https://'
    else
      _proto='http://'
    end
    _job_api="#{_proto}#{server_fqdn}#{endpoint}"
#    warn "OctoPrint: #{_job_api}"
    uri = URI(_job_api)
    # Create client
#    warn "OctoPrint: getOctoPrintStatus: URI: host #{uri.host}"
#    warn "OctoPrint: getOctoPrintStatus: URI: port #{uri.port}"
#    warn "OctoPrint: getOctoPrintStatus: URI: request_uri #{uri.request_uri}"
    http = Net::HTTP.new(uri.host,uri.port)
    if @api_ssl_enable
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    # Create Request
    req =  Net::HTTP::Get.new(uri.request_uri)
    # Fetch Request
    res = http.request(req)
#    warn "OctoPrint: getOctoPrintStatus: Response HTTP Status Code: #{res.code}"
#    warn "OctoPrint: getOctoPrintStatus: Response HTTP Response Body: #{res.body}"
    status_data=JSON.parse(res.body)
  rescue Exception => e
#    warn "OctoPrint: getOctoPrintStatus: HTTP Request failed (#{e.message})"
  end
  status_data
end
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every "#{@frequency}s", first_in: 0 do
	data = getOctoPrintStatus(@octo_server,@api_port,@api_key,@job_endpoint,@api_ssl_enable)
  if data
    progress=data['progress']['completion'].round(2)
    send_event('octoprint_status', octoPrintPrintTimeRemaining: data['progress']['printTimeLeft'], octoPrintFileName: data['job']['file']['name'], octoPrintPrintTime: data['progress']['printTime'],octoPrintProgress: progress, octoPrintState: data['state'] )
  end
end
