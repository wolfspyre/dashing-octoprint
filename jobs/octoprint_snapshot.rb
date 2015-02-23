#octoprint.rb
#
require 'net/http'
require 'yaml'
#require 'pry'
##############################################
# Load configuration
##############################################
CONFIG_DIR = File.join(File.expand_path('..'), "conf.d")
CONFIG_MAIN_FILE = File.join(CONFIG_DIR, "octoprint_defaults.yaml")
CONFIG_OVERRIDE_FILE = File.join(CONFIG_DIR, "octoprint_override.yaml")
octoprint_config = YAML.load_file(CONFIG_MAIN_FILE)
if File.exists?(CONFIG_OVERRIDE_FILE)
  octoprint_config = octoprint_config.merge(YAML.load_file(CONFIG_OVERRIDE_FILE))
end

@api_port=octoprint_config['octo_server_api_port']
@current_file=octoprint_config['octo_server_latest_filename']
@last_file=octoprint_config['octo_server_last_filename']
@api_key=octoprint_config['octo_server_api_key']
@octo_server=octoprint_config['octo_server_fqdn']
@snapshot_url=octoprint_config['octo_server_snapshot_url']
@webcam_port=octoprint_config['octo_server_webcam_port']
@webcam_frequency=octoprint_config['octo_server_webcam_poll_interval']
warn "OctoPrint: #{CONFIG_DIR}"
warn "OctoPrint: #{CONFIG_MAIN_FILE}"
warn "OctoPrint: #{CONFIG_OVERRIDE_FILE}"
warn "OctoPrint: #{@api_port}"
warn "OctoPrint: #{@current_file}"
warn "OctoPrint: #{@last_file}"
warn "OctoPrint: #{@api_key}"
warn "OctoPrint: #{@octo_server}"
warn "OctoPrint: #{@snapshot_url}"
warn "OctoPrint: #{@webcam_port}"
warn "OctoPrint: #{@webcam_frequency}"
def fetch_image(host,old_file,new_file, cam_port, cam_url)
	`rm #{old_file}`
	`mv #{new_file} #{old_file}`
	Net::HTTP.start(host,cam_port) do |http|
		req = Net::HTTP::Get.new(cam_url)
		response = http.request(req)
		open(new_file, "wb") do |file|
			file.write(response.body)
		end
	end
	new_file
end
def make_web_friendly(file)
  "/" + File.basename(File.dirname(file)) + "/" + File.basename(file)
end
# :first_in sets how long it takes before the job is first run. In this case, it is run immediately
SCHEDULER.every @webcam_frequency, first_in: 0 do
	new_snapshot = fetch_image(@octoserver,@last_file,@current_file,@webcam_port,@snapshot_url)
	if not File.exists?(@current_file)
		warn "Failed to Get Camera Image"
	end
	send_event('octoprint_snapshot', octo_image: make_web_friendly(@new_snapshot))
	sleep(@webcam_frequency)
	send_event('octoprint_snapshot', octo_image: make_web_friendly(new_snapshot))
end
