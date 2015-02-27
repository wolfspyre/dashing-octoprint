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

@api_key=octoprint_config['octo_server_api_key']
@api_port=octoprint_config['octo_server_api_port']
@api_ssl_enable=octoprint_config['octo_server_api_ssl']
@bed_color_actual=octoprint_config['octo_server_printer_bed_temp_graph_color_actual']
@bed_color_target=octoprint_config['octo_server_printer_bed_temp_graph_color_target']
@bed_graph_enable=octoprint_config['octo_server_printer_bed_temp_graph_enable']
@frequency=octoprint_config['octo_server_api_poll_interval']
@octo_server=octoprint_config['octo_server_fqdn']
@printer_endpoint=octoprint_config['octo_server_api_printer_endpoint']
@tool0_color_actual=octoprint_config['octo_server_printer_tool_0_temp_graph_color_actual']
@tool0_color_target=octoprint_config['octo_server_printer_tool_0_temp_graph_color_target']
@tool0_graph_enable=octoprint_config['octo_server_printer_bed_temp_graph_enable']

if @tool0_graph_enable
  tool0_graph = DashingGraph.new 'actual' => @tool0_color_actual, 'target' => @tool0_color_target
end
if @bed_graph_enable
  bed_graph = DashingGraph.new 'actual' => @bed_color_actual, 'target' => @bed_color_target
end
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
    _printer_api="#{_proto}#{server_fqdn}#{endpoint}"
#    warn "OctoPrint: #{_printer_api}"
    uri = URI(_printer_api)
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
#http://stackoverflow.com/questions/4136248/how-to-generate-a-human-readable-time-range-using-ruby-on-rails
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every "#{@frequency}s", first_in: 0 do
	data = getOctoPrintStatus(@octo_server,@api_port,@api_key,@printer_endpoint,@api_ssl_enable)
  time = Time.new.to_datetime.to_i
  if data
    if @bed_graph_enable
      bed_actual=data['temps']['bed']['actual']
      bed_target=data['temps']['bed']['target']
      bed_graph.add_point 'actual', time, 1
      bed_graph.add_point 'target', time, 1
      send_event('octoprint_bed_graph' bed_graph)
      sleep 1
    end
    if @tool0_graph_enable
      tool0_actual=data['temps']['tool0']['actual']
      tool0_target=data['temps']['tool0']['target']
      tool0_graph.add_point 'actual', time, 1
      tool0_graph.add_point 'target', time, 1
      send_event('octoprint_tool_graph' tool0_graph)
    end
  end
end
