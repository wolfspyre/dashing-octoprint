#octoprint.rb
#
require 'net/http'
require 'yaml'
#require 'pry'
##############################################
# Load configuration
##############################################
octoConfDir = File.join(File.expand_path('..'), "conf.d")
octoConfMain = File.join(octoConfDir, "octoprint_defaults.yaml")
octoConfOverride = File.join(octoConfDir, "octoprint_override.yaml")
octoprint_config = YAML.load_file(octoConfMain)
if File.exists?(octoConfOverride)
  warn "OctoPrint: Merging Override"
  octoprint_config = octoprint_config.merge(YAML.load_file(octoConfOverride))
end

@api_port=octoprint_config['octo_server_api_port']
@current_file=octoprint_config['octo_server_latest_filename']
@last_file=octoprint_config['octo_server_last_filename']
@api_key=octoprint_config['octo_server_api_key']
@octo_server=octoprint_config['octo_server_fqdn']
@snapshot_url=octoprint_config['octo_server_snapshot_url']
@webcam_port=octoprint_config['octo_server_webcam_port']
@webcam_frequency=octoprint_config['octo_server_webcam_poll_interval']
warn "OctoPrint: #{octoConfDir}"
warn "OctoPrint: #{octoConfMain}"
warn "OctoPrint: #{octoConfOverride}"
warn "OctoPrint: #{@api_port}"
warn "OctoPrint: #{@current_file}"
warn "OctoPrint: #{@last_file}"
warn "OctoPrint: #{@api_key}"
warn "OctoPrint: #{@octo_server}"
warn "OctoPrint: #{@snapshot_url}"
warn "OctoPrint: #{@webcam_port}"
warn "OctoPrint: #{@webcam_frequency}"
def fetch_image(host,old_file,new_file, cam_port, cam_url)
  begin
    warn "OctoPrint: fetch_image: #{host}"
    warn "OctoPrint: fetch_image: #{old_file}"
    warn "OctoPrint: fetch_image: #{new_file}"
    warn "OctoPrint: fetch_image: #{cam_port}"
    warn "OctoPrint: fetch_image: #{cam_url}"
    if File.exists?(old_file)
      warn "OctoPrint: fetch_image: deleting #{old_file}"
      File.delete(old_file)
    end
    if File.exists?(new_file)
      warn "OctoPrint: fetch_image: moving #{new_file} -> #{old_file}"
      FileUtils.mv new_file, old_file, :verbose => true
    end
    # Create client
    http = Net::HTTP.new(host,cam_port)
    # Create Request
    req =  Net::HTTP::Get.new(cam_url)
    # Fetch Request
    res = http.request(req)
    warn "OctoPrint: fetch_image: Response HTTP Status Code: #{res.code}"
    warn "OctoPrint: fetch_image: Response HTTP Response Body: #{res.body}"
  rescue Exception => e
    warn "OctoPrint: fetch_image: HTTP Request failed (#{e.message})"
  end
  open(new_file, "wb") do |file|
    file.write(res.body)
  end
  new_file
#	`rm #{old_file}`
#	`mv #{new_file} #{old_file}`
#	Net::HTTP.start(host,cam_port) do |http|
#		req = Net::HTTP::Get.new(cam_url)
#		response = http.request(req)
#		open(new_file, "wb") do |file|
#			file.write(response.body)
#		end
#	end
#	new_file
end
def make_web_friendly(file)
  "/" + File.basename(File.dirname(file)) + "/" + File.basename(file)
end
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every @webcam_frequency, first_in: 0 do
	new_snapshot = fetch_image(@octo_server,@last_file,@current_file,@webcam_port,@snapshot_url)
	if not File.exists?(@current_file)
		warn "Failed to Get Camera Image"
	end
	send_event('octoprint_snapshot', octo_image: make_web_friendly(@new_snapshot))
	sleep(@webcam_frequency)
	send_event('octoprint_snapshot', octo_image: make_web_friendly(new_snapshot))
end
