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
@graph_depth_max=99
@api_key=octoprint_config['octo_server_api_key']
@api_port=octoprint_config['octo_server_api_port']
@api_ssl_enable=octoprint_config['octo_server_api_ssl']
@bed_color_actual=octoprint_config['octo_server_printer_bed_temp_graph_color_actual']
@bed_color_background=octoprint_config['octo_server_printer_bed_temp_graph_color_background']
@bed_color_target=octoprint_config['octo_server_printer_bed_temp_graph_color_target']
@bed_graph_enable=octoprint_config['octo_server_printer_bed_temp_graph_enable']
@completion_bgcolor=octoprint_config['octo_server_completion_bgcolor']
@completion_fgcolor=octoprint_config['octo_server_completion_fgcolor']
@file_color_position=octoprint_config['octo_server_job_graph_file_color_position']
@file_color_total=octoprint_config['octo_server_job_graph_file_color_total']
@frequency=octoprint_config['octo_server_api_poll_interval']
@graph_depth_file=octoprint_config['octo_server_graph_depth']
@history_enable=octoprint_config['octo_server_history_enable']
@history_file=octoprint_config['octo_server_history_file']
@job_endpoint=octoprint_config['octo_server_api_job_endpoint']
@job_graph_enable=octoprint_config['octo_server_job_graph_enable']
@job_time_units=octoprint_config['octo_server_job_graph_time_units']
@octo_server=octoprint_config['octo_server_fqdn']
@printer_endpoint=octoprint_config['octo_server_api_printer_endpoint']
@time_color_elapsed=octoprint_config['octo_server_job_graph_time_color_elapsed']
@time_color_estimated=octoprint_config['octo_server_job_graph_time_color_estimated']
@time_color_remaining=octoprint_config['octo_server_job_graph_time_color_remaining']
@tool0_color_actual=octoprint_config['octo_server_printer_tool_0_temp_graph_color_actual']
@tool0_color_background=octoprint_config['octo_server_printer_tool_0_temp_graph_color_background']
@tool0_color_target=octoprint_config['octo_server_printer_tool_0_temp_graph_color_target']
@tool0_graph_enable=octoprint_config['octo_server_printer_tool_0_temp_graph_enable']

if @graph_depth_file.to_i > @graph_depth_max
  @graph_depth = @graph_depth_max
  warn "OctoPrint: Graph Depth greater than 99 is unsupported. "
else
  @graph_depth = @graph_depth_file
end

if @history_enable
  warn   "OctoPrint: History enabled"
  octoHistoryFile=@history_file
  if File.exists?(octoHistoryFile)
    warn   "OctoPrint: History file exists"
    begin
      octoprint_history = YAML.load_file(octoHistoryFile)
    rescue
      warn "OctoPrint: But YAML.load_file needed to be rescued. Reinitializing"
      octoprint_history=Hash.new
      octoprint_history.to_yaml
      #warn   "OctoPrint: History: #{octoprint_history}"
      File.open(octoHistoryFile, "w") { |f|
        f.write octoprint_history
      }
    else
      warn "OctoPrint: But YAML.load_file couldn't load it for some reason. Reinitializing"
      octoprint_history=Hash.new
      octoprint_history.to_yaml
      #warn   "OctoPrint: History: #{octoprint_history}"
      File.open(octoHistoryFile, "w") { |f|
        f.write octoprint_history
      }
    end
  else
    warn "OctoPrint: New history file initialized"
    octoprint_history=Hash.new
  end
  #sanity check
  ['bed_actual_datapoints', 'bed_target_datapoints',
  'tool0_actual_datapoints', 'tool0_target_datapoints',
  'completion_datapoints', 'estimated_print_time_datapoints',
  'file_position_datapoints', 'file_size_datapoints',
  'print_time_datapoints', 'print_time_left_datapoints',].each do |hist|
    if !octoprint_history["#{hist}"]
      warn "OctoPrint: History initialized, but #{hist} not in octoprint_history. Initializing."
      octoprint_history["#{hist}"]=Array.new
    end
  end
  octoprint_history.to_yaml
  #warn   "OctoPrint: History: #{octoprint_history}"
  File.open(octoHistoryFile, "w") { |f|
    f.write octoprint_history
  }
end

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
  tool0_actual_datapoints=[]
  tool0_target_datapoints=[]
  if @history_enable
    if octoprint_history['tool0_actual_datapoints'] && !octoprint_history['tool0_actual_datapoints'].empty?
#      warn "OctoPrint: importing tool0_actual_datapoints from history file"
      tool0_actual_datapoints=octoprint_history['tool0_actual_datapoints']
    else
      warn "OctoPrint: History enabled, but tool0_actual_datapoints not found. Initializing"
#      tool0_actual_datapoints=[]
    end
    if octoprint_history['tool0_target_datapoints'] && !octoprint_history['tool0_target_datapoints'].empty?
#      warn "OctoPrint: importing tool0_target_datapoints from history file"
      tool0_target_datapoints=octoprint_history['tool0_target_datapoints']
    else
      warn "OctoPrint: History enabled, but tool0_target_datapoints not found. Initializing"
#      tool0_target_datapoints=[]
    end
  else
    warn "OctoPrint: History disabled. Initializing tool0 data"
  end
end
if @bed_graph_enable
  if @history_enable
    [ 'bed_actual_datapoints', 'bed_target_datapoints'].each do |var|
      if octoprint_history["#{var}"] && !octoprint_history["#{var}"].empty?
#        warn "OctoPrint: Bed History enabled. Populating #{var} from file."
        instance_variable_set("@#{var}", octoprint_history["#{var}"])
      else
        warn "OctoPrint: Bed History enabled but #{var} nonexistent or empty. Creating"
        instance_variable_set("@#{var}", Array.new)
        octoprint_history["#{var}"]=Array.new
      end
    end
  else
#    warn "OctoPrint: History disabled. Initializing bed data"
      @bed_actual_datapoints=[]
      @bed_target_datapoints=[]
  end
end
if @tool1_graph_enable
  warn "Graphing of tool1 is not currently implemented. Pull requests welcome."
end

if @job_graph_enable
  if @history_enable
    [ 'completion_datapoints', 'estimated_print_time_datapoints', 'file_position_datapoints', 'file_size_datapoints', 'print_time_datapoints', 'print_time_left_datapoints'].each do |var|
      if octoprint_history["#{var}"] && !octoprint_history["#{var}"].empty?
#        warn "OctoPrint: Job History enabled. Populating #{var} from file."
        instance_variable_set("@#{var}", octoprint_history["#{var}"])
      else
        warn "OctoPrint: Job History enabled but #{var} nonexistent or empty. Creating"
        instance_variable_set("@#{var}", Array.new)
        octoprint_history["#{var}"]=Array.new
      end
    end
  else
    @completion_datapoints=[]
    @estimated_print_time_datapoints=[]
    @file_position_datapoints=[]
    @file_size_datapoints=[]
    @print_time_datapoints=[]
    @print_time_left_datapoints=[]
  end



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
#hacky, but I don't want to require a gem
#http://stackoverflow.com/questions/16026048/pretty-file-size-in-ruby
class Integer
  def to_filesize
    {
      'B'  => 1024,
      'KB' => 1024 * 1024,
      'MB' => 1024 * 1024 * 1024,
      'GB' => 1024 * 1024 * 1024 * 1024,
      'TB' => 1024 * 1024 * 1024 * 1024 * 1024
    }.each_pair { |e, s| return "#{(self.to_f / (s / 1024)).round(2)}#{e}" if self < s }
  end
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
      @bed_actual_datapoints<<bed_actual_now
      @bed_target_datapoints<<bed_target_now
      bed_colors="#{@bed_color_actual}:#{@bed_color_target}"
      bed_graphite = [
        {
          target: "Actual: #{bed_actual}", datapoints: @bed_actual_datapoints
        },
        {
          target: "Target: #{bed_target}", datapoints: @bed_target_datapoints
        }
      ]
#      warn "OctoPrint: bed_graphite data: #{bed_graphite}"
      send_event('octoprint_bed_graph', series: bed_graphite, colors: bed_colors)
      if @history_enable
        octoprint_history['bed_actual_datapoints']<<bed_actual_now
        octoprint_history['bed_target_datapoints']<<bed_target_now
      end
      if @bed_actual_datapoints.length >= @graph_depth.to_i
        @bed_actual_datapoints=@bed_actual_datapoints.drop(@bed_actual_datapoints.length - @graph_depth.to_i)
      end
      if @bed_target_datapoints.length >= @graph_depth.to_i
        @bed_target_datapoints=@bed_target_datapoints.drop(@bed_target_datapoints.length - @graph_depth.to_i)
      end
    end
    if @tool0_graph_enable
      tool0_actual=data['temps']['tool0']['actual'].to_i
      tool0_target=data['temps']['tool0']['target'].to_i
      tool0_actual_now=[tool0_actual,time]
      tool0_target_now=[tool0_target,time]
      tool0_actual_datapoints<<tool0_actual_now
      tool0_target_datapoints<<tool0_target_now
      tool0_colors="#{@tool0_color_actual}:#{@tool0_color_target}"
      tool0_graphite = [
        {
          target: "Actual: #{tool0_actual}", datapoints: tool0_actual_datapoints
        },
        {
          target: "Target: #{tool0_target}", datapoints: tool0_target_datapoints
        }
      ]
#      warn "OctoPrint: tool0_graphite data: #{tool0_graphite}"
      send_event('octoprint_tool0_graph', series: tool0_graphite, colors: tool0_colors )
      if @history_enable
        octoprint_history['tool0_actual_datapoints']<<tool0_actual_now
        octoprint_history['tool0_target_datapoints']<<tool0_target_now
      end
      if tool0_actual_datapoints.length >= @graph_depth.to_i
        tool0_actual_datapoints=tool0_actual_datapoints.drop(tool0_actual_datapoints.length - @graph_depth.to_i)
      end
      if tool0_target_datapoints.length >= @graph_depth.to_i
        tool0_target_datapoints=tool0_target_datapoints.drop(tool0_target_datapoints.length - @graph_depth.to_i)
      end
    end
  end
end
#history job
#TODO: should this be done in the other jobs instead? would have a greater chance
#  at not losing data, but would increase writes, might introduce locking issues if jobs are parallelized?
#
SCHEDULER.every "#{@frequency}s", first_in: 0 do
  if @history_enable
#    warn "OctoPrint: History Job enabled"
    octoprint_history.each_pair do |k,v|
      if v.length >= @graph_depth.to_i
#        warn "OctoPrint: History depth: #{k}: #{v.length} Trimming"
        octoprint_history[k]= v.drop(1)
#        warn "OctoPrint: History depth: now #{octoprint_history[k].length}"
      else
#        warn "OctoPrint: History depth: #{k}: #{v.length} "
      end
    end
#      warn "OctoPrint: History job Writing #{octoprint_history} to #{@history_file}"
    warn "OctoPrint: History job Writing to #{@history_file}"
    File.open(@history_file, 'w'){|f|
      f.write octoprint_history.to_yaml
    }
  else
    warn "OctoPrint: History disabled"
  end
end

#    octoprint_history['bed_actual_datapoints']<<bed_actual_datapoints
#    octoprint_history['bed_target_datapoints']<<bed_target_datapoints
#    File.open(@history_file, 'w'){|f|
#      f.write octoprint_history.to_yaml
#    }
#warn "OctoPrint: History job Writing #{octoprint_history} to #{@history_file}"
#  else
#warn "OctoPrint: History Job disabled"
#  end
#end
SCHEDULER.every "#{@frequency}s", first_in: 0 do
  if @job_graph_enable
	  job = getOctoPrintStatus(@octo_server,@api_port,@api_key,@job_endpoint,@api_ssl_enable)
#    warn "OctoPrint: #{job}"
    time = Time.now.to_i
    if job
      estimated_print_time=job['estimatedPrintTime'].to_i

      completion=(job['progress']['completion'].to_f).round(2)
      completion_now=[completion,time]
      @completion_datapoints<<completion_now
      file_position=job['progress']['filepos'].to_i
      file_position_now=[file_position,time]
      @file_position_datapoints<<file_position_now
      file_size=job['job']['file']['size'].to_i
      file_size_now=[file_size,time]
      @file_size_datapoints<<file_size_now
      _print_time=job['progress']['printTime'].to_i
      if @job_time_units_normalized == 'm'
        print_time = sec_to_min(_print_time)
      else
        print_time = _print_time
      end
      print_time_now=[print_time,time]
      @print_time_datapoints<<print_time_now
      _print_time_left=job['progress']['printTimeLeft'].to_i
      if @job_time_units_normalized == 'm'
        print_time_left = sec_to_min(_print_time_left)
      else
        print_time_left = _print_time_left
      end
      print_time_left_now=[print_time_left,time]
      @print_time_left_datapoints<<print_time_left_now
      _estimated_print_time=job['job']['estimatedPrintTime'].to_i
      if @job_time_units_normalized == 'm'
        estimated_print_time = sec_to_min(_estimated_print_time)
      else
        estimated_print_time = _estimated_print_time
      end
      estimated_print_time_now=[estimated_print_time,time]
      @estimated_print_time_datapoints<<estimated_print_time_now
      time_colors="#{@time_color_estimated}:#{@time_color_remaining}:#{@time_color_elapsed}"
      file_colors="#{@file_color_position}:#{@file_color_total}"
#      warn "OctoPrint: completion:           #{completion}"
#      warn "OctoPrint: print_time:           #{print_time}           (raw: #{_print_time})"
#      warn "OctoPrint: print_time_left:      #{print_time_left}      (raw: #{_print_time_left})"
#      warn "OctoPrint: estimated_print_time: #{estimated_print_time} (raw: #{_estimated_print_time})"
      job_graphite = [
        {
          target: "Job Position: #{file_position.to_filesize}", datapoints: @file_position_datapoints
        },
        {
          target: "Job Total Size: #{file_size.to_filesize}", datapoints: @file_size_datapoints
        },
      ]
      time_graphite = [
        {
          target: "Estimated Total: #{estimated_print_time}#{@job_time_units_normalized}", datapoints: @estimated_print_time_datapoints
        },
        {
          target: "Remaining: #{print_time_left}#{@job_time_units_normalized}", datapoints: @print_time_left_datapoints
        },
        {
          target: "Elapsed: #{print_time}#{@job_time_units_normalized}", datapoints: @print_time_datapoints
        }

      ]
#      warn "OctoPrint: bed_graphite job: #{bed_graphite}"
      send_event('octoprint_job_graph', series: job_graphite, colors: file_colors)
      send_event('octoprint_time_graph', series: time_graphite, colors: time_colors)
      send_event('octoprint_completion', value: completion, bgcolor: @completion_bgcolor, fgcolor: @completion_fgcolor)
      if @history_enable
        octoprint_history['completion_datapoints']<<completion_now
        octoprint_history['file_position_datapoints']<<file_position_now
        octoprint_history['file_size_datapoints']<<file_size_now
        octoprint_history['print_time_datapoints']<<print_time_now
        octoprint_history['print_time_left_datapoints']<<print_time_left_now
        octoprint_history['estimated_print_time_datapoints']<<estimated_print_time_now
      end
      if @completion_datapoints.length >= @graph_depth.to_i
        @completion_datapoints=@completion_datapoints.drop(@completion_datapoints.length - @graph_depth.to_i)
      end
      if @file_position_datapoints.length >= @graph_depth.to_i
        @file_position_datapoints=@file_position_datapoints.drop(@file_position_datapoints.length - @graph_depth.to_i)
      end
      if @file_size_datapoints.length >= @graph_depth.to_i
        @file_size_datapoints=@file_size_datapoints.drop(@file_size_datapoints.length - @graph_depth.to_i)
      end
      if @print_time_datapoints.length >= @graph_depth.to_i
        @print_time_datapoints=@print_time_datapoints.drop(@print_time_datapoints.length - @graph_depth.to_i)
      end
      if @print_time_left_datapoints.length >= @graph_depth.to_i
        @print_time_left_datapoints=@print_time_left_datapoints.drop(@print_time_left_datapoints.length - @graph_depth.to_i)
      end
      if @estimated_print_time_datapoints.length >= @graph_depth.to_i
        @estimated_print_time_datapoints=@estimated_print_time_datapoints.drop(@estimated_print_time_datapoints.length - @graph_depth.to_i)
      end
    end
  end
end
