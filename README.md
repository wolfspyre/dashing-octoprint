#Dashing-OctoPrint

![OctoPrint Dashboard Snapshot](skitch.jpg)
####A templatized 3D printing dashboard

This aims to be a [Dashing](http://shopify.github.io/dashing/#overview) widget and sample dashboard for viewing metrics and data from your [OctoPrint](http://octoprint.org) rig. This is developed against [OctoPi](https://github.com/guysoft/OctoPi).

##Installation

-	Clone [the repository](https://github.com/wolfspyre/dashing-octoprint)
-	Run the `scripts/deploy.sh` shell script, which will perform the needed actions to install this widget.
-	Restart Dashing to pick up the new changes.
-	Navigate to the newly installed octoprint dashboard in your browser, and revel in the dashboardy goodness of your octoprint rig.

###Required Widgets

The graphs depend on [Jason Walton's Rickshawgraph plugin](https://gist.github.com/jwalton/6614023). The process for installation is pretty straightforward. You should review the installation instructions contained within the repo, as they may supersede these; but this should get you going. There are two ways to do it.

-	Manual Installation

	-	Create a `rickshawgraph` directory in the `widgets` directory of your dashboard installation.
	-	Place the [rickshawgraph.coffee](https://gist.github.com/jwalton/6614023/raw/07c3a382845fbc27e0523d7f2de43e43e0904c4b/rickshawgraph.coffee), [rickshawgraph.html](https://gist.github.com/jwalton/6614023/raw/da626313b868c685e515db19bfd98c68db13d649/rickshawgraph.html), and [rickshawgraph.scss](https://gist.github.com/jwalton/6614023/raw/8d1fbd74b4915b3b96b899b7c723cf078cf53fc9/rickshawgraph.scss) file, the Inside the newly created `widgets\rickshawgraph` directory
	-	Restart Dashing.

-	Automatic Installation

	-	from within your dashboard directory; install the gist with the `dashing install` command:
		-	`dashing install 6614023`
	-	Restart Dashing.

---

##Configuration

The `octoprint_defaults.yaml` file tunes the behavior of the job. it is meant to provide you an example configuration of the configurable parameters. You are meant to create an `octoprint_overrides.yaml` file in the `conf.d` directory with your specific settings. This permits you to update the default configuration file automatically, while simultaneously maintaining a custom local configuration.

`octo_server_api_job_endpoint`: *string* The endpoint to query for jobs. **Default:** '/api/job'
`octo_server_api_key`: *string* Your OctoPrint API key. **Currently unnecessary**. May be required in the future. **Default:** 'CHANGEME'
`octo_server_api_poll_interval`: '30'
`octo_server_api_port`: '443'
`octo_server_api_printer_endpoint`: '/api/printer'
`octo_server_api_ssl`: true
`octo_server_fqdn`: 'octoprint.example.com'
`octo_server_graph_depth`: '300'
`octo_server_history_enable`: true
`octo_server_history_file`: 'logs/octoprint_history.yaml'
`octo_server_job_graph_enable`: true
`octo_server_job_graph_time_units`: 'minutes'
`octo_server_job_graph_time_color_elapsed`: '#0f0'
`octo_server_job_graph_time_color_estimated`: '#00f'
`octo_server_job_graph_time_color_remaining`: '#f00'
`octo_server_job_graph_file_color_position`: '#00f'
`octo_server_job_graph_file_color_total`: '#f00'
`octo_server_completion_fgcolor`: '#333'
`octo_server_completion_bgcolor`: '#3c3'
`octo_server_last_filename`: 'assets/images/octocam/last.jpeg'
`octo_server_latest_filename`: 'assets/images/octocam/latest.jpeg'
`octo_server_printer_bed_temp_graph_color_actual`: '#00ff00'
`octo_server_printer_bed_temp_graph_color_background`: '#cccccc'
`octo_server_printer_bed_temp_graph_color_target`: '#ff0000'
`octo_server_printer_bed_temp_graph_enable`: true
`octo_server_printer_tool_0_temp_graph_color_actual`: '#00ff00'
`octo_server_printer_tool_0_temp_graph_color_background`: '#cccccc'
`octo_server_printer_tool_0_temp_graph_color_target`: '#ff0000'
`octo_server_printer_tool_0_temp_graph_enable`: true
`octo_server_printer_tool_1_temp_graph_color_actual`: '#00ff00'
`octo_server_printer_tool_1_temp_graph_color_target`: '#ff0000'
`octo_server_printer_tool_1_temp_graph_enable`: false
`octo_server_snapshot_url`: 'https`://octoprint.example.com/webcam/?action=snapshot'
`octo_server_webcam_poll_interval`: '30'
`octo_server_webcam_port`: '443'
`octo_server_webcam_ssl`: true
