#octoprint_graphs.rb
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
@graph_depth=octoprint_config['octo_server_graph_depth']
@job_endpoint=octoprint_config['octo_server_api_job_endpoint']
@job_time_units=octoprint_config['octo_server_job_graph_time_units']
@job_graph_enable=octoprint_config['octo_server_job_graph_enable']
@octo_server=octoprint_config['octo_server_fqdn']
@printer_endpoint=octoprint_config['octo_server_api_printer_endpoint']
@tool0_color_actual=octoprint_config['octo_server_printer_tool_0_temp_graph_color_actual']
@tool0_color_target=octoprint_config['octo_server_printer_tool_0_temp_graph_color_target']
@tool0_graph_enable=octoprint_config['octo_server_printer_tool_0_temp_graph_enable']

case @job_time_units
when 's', 'sec','seconds'
  @job_time_units_normalized='s'
when 'm', 'min', 'minutes'
  @job_time_units_normalized='m'
else
  warn "OctoPrint: Config variable 'octo_server_job_graph_time_units' has invalid value"
  warn "OctoPrint: Current value: #{@job_time_units}. Defaulting to seconds."
  @job_time_units_normalized='s'
end
def sec_to_min(seconds)
  #divide by 60.
  seconds.div(60)
end
#warn "OctoPrint: api_key: #{@api_key}"
#warn "OctoPrint: api_port: #{@api_port}"
#warn "OctoPrint: api_ssl_enable: #{@api_ssl_enable}"
#warn "OctoPrint: bed_color_actual: #{@bed_color_actual}"
#warn "OctoPrint: bed_color_target: #{@bed_color_target}"
#warn "OctoPrint: bed_graph_enable: #{@bed_graph_enable}"
#warn "OctoPrint: frequency: #{@frequency}"
#warn "OctoPrint: octo_server: #{@octo_server}"
#warn "OctoPrint: printer_endpoint: #{@printer_endpoint}"
#warn "OctoPrint: tool0_color_actual: #{@tool0_color_actual}"
#warn "OctoPrint: tool0_color_target: #{@tool0_color_target}"
#warn "OctoPrint: tool0_graph_enable: #{@tool0_graph_enable}"

#see 'Passing Data' section of the rickshawgraphs plugin
#
#https://gist.github.com/jwalton/6614023
#graphite = [
#  {
#    target: "stats_counts.http.ok",
#    datapoints: [[10, 1378449600], [40, 1378452000], [53, 1378454400], [63, 1378456800], [27, 1378459200]]
#  },
#  {
#    target: "stats_counts.http.err",
#    datapoints: [[0, 1378449600], [4, 1378452000], [nil, 1378454400], [3, 1378456800], [0, 1378459200]]
#  }
#]
#send_event('http', series: graphite)
#
if @tool0_graph_enable
  tool0_graph=[]
  tool0_actual_datapoints=[]
  tool0_target_datapoints=[]
end
if @bed_graph_enable
  bed_graph=[]
  bed_actual_datapoints=[]
  bed_target_datapoints=[]
end
if @job_graph_enable
  job_graph=[]
  completion_datapoints=[]
  estimated_print_time_datapoints=[]
  file_position_datapoints=[]
  file_size_datapoints=[]
  print_time_datapoints=[]
  print_time_left_datapoints=[]
end
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
#  warn "OctoPrint: #{data}"
  time = Time.now.to_i
  if data
    if @bed_graph_enable
      bed_actual=data['temps']['bed']['actual'].to_i
      bed_target=data['temps']['bed']['target'].to_i
      bed_actual_now=[bed_actual,time]
      bed_target_now=[bed_target,time]
      bed_actual_datapoints<<bed_actual_now
      bed_target_datapoints<<bed_target_now
      bed_actual_datapoints=bed_actual_datapoints.take(@graph_depth.to_i)
      bed_target_datapoints=bed_target_datapoints.take(@graph_depth.to_i)
      bed_graphite = [
        {
          target: "Actual Temp", datapoints: bed_actual_datapoints
        },
        {
          target: "Target Temp", datapoints: bed_target_datapoints
        }
      ]
#      warn "OctoPrint: bed_graphite data: #{bed_graphite}"
      send_event('octoprint_bed_graph', series: bed_graphite)
      sleep 1
    end
    if @tool0_graph_enable
      tool0_actual=data['temps']['tool0']['actual'].to_i
      tool0_target=data['temps']['tool0']['target'].to_i
      tool0_actual_now=[tool0_actual,time]
      tool0_target_now=[tool0_target,time]
      tool0_actual_datapoints<<tool0_actual_now
      tool0_target_datapoints<<tool0_target_now
      tool0_actual_datapoints=tool0_actual_datapoints.take(@graph_depth.to_i)
      tool0_target_datapoints=tool0_target_datapoints.take(@graph_depth.to_i)
      tool0_graphite = [
        {
          target: "Actual Temp", datapoints: tool0_actual_datapoints
        },
        {
          target: "Target Temp", datapoints: tool0_target_datapoints
        }
      ]
#      warn "OctoPrint: tool0_graphite data: #{tool0_graphite}"
      send_event('octoprint_tool0_graph', series: tool0_graphite)
    end
  end
end
SCHEDULER.every "#{@frequency}s", first_in: 0 do
  if @job_graph_enable
	  job = getOctoPrintStatus(@octo_server,@api_port,@api_key,@job_endpoint,@api_ssl_enable)
#    warn "OctoPrint: #{job}"
    time = Time.now.to_i
    if job
      estimated_print_time=job['estimatedPrintTime'].to_i

      completion=(job['progress']['completion'].to_f).round(2)
      completion_now=[completion,time]
      completion_datapoints<<completion_now
      completion_datapoints=completion_datapoints.take(@graph_depth.to_i)

      file_position=job['progress']['filepos'].to_i
      file_position_now=[file_position,time]
      file_position_datapoints<<file_position_now
      file_position_datapoints=file_position_datapoints.take(@graph_depth.to_i)

      file_size=job['job']['file']['size'].to_i
      file_size_now=[file_size,time]
      file_size_datapoints<<file_size_now
      file_size_datapoints=file_size_datapoints.take(@graph_depth.to_i)

      _print_time=job['progress']['printTime'].to_i
      if @job_time_units_normalized == 'm'
        print_time = sec_to_min(_print_time)
      else
        print_time = _print_time
      end
      print_time_now=[print_time,time]
      print_time_datapoints<<print_time_now
      print_time_datapoints=print_time_datapoints.take(@graph_depth.to_i)

      _print_time_left=job['progress']['printTimeLeft'].to_i
      if @job_time_units_normalized == 'm'
        print_time_left = sec_to_min(_print_time_left)
      else
        print_time_left = _print_time_left
      end
      print_time_left_now=[print_time_left,time]
      print_time_left_datapoints<<print_time_left_now
      print_time_left_datapoints=print_time_left_datapoints.take(@graph_depth.to_i)

      _estimated_print_time=job['estimatedPrintTime'].to_i
      if @job_time_units_normalized == 'm'
        estimated_print_time = sec_to_min(_estimated_print_time)
      else
        estimated_print_time = _estimated_print_time
      end
      estimated_print_time_now=[estimated_print_time,time]
      estimated_print_time_datapoints<<estimated_print_time_now
      estimated_print_time_datapoints=estimated_print_time_datapoints.take(@graph_depth.to_i)
      warn "OctoPrint: completion:           #{completion}"
      warn "OctoPrint: print_time:           #{print_time}"
      warn "OctoPrint: print_time_left:      #{print_time_left}"
      warn "OctoPrint: estimated_print_time: #{estimated_print_time}"
      job_graphite = [
        {
          target: "Job Position", datapoints: file_position_datapoints
        },
        {
          target: "Job Total Size", datapoints: file_size_datapoints
        },
      ]
      time_graphite = [
        {
          target: "Print Time", datapoints: print_time_datapoints
        },
        {
          target: "Print Time Left", datapoints: print_time_left_datapoints
        },
        {
          target: "Estimated Print Time", datapoints: estimated_print_time_datapoints
        }
      ]
#      warn "OctoPrint: bed_graphite job: #{bed_graphite}"
      send_event('octoprint_job_graph', series: job_graphite)
      sleep 1
      send_event('octoprint_time_graph', series: time_graphite)
      sleep 1
      send_event('octoprint_completion', value: completion, bgcolor: '333', fgcolor: '3c3')
    end
  end
end
