#Dashing-OctoPrint

####A templatized 3D printing dashboard

This aims to be a [Dashing](http://shopify.github.io/dashing/#overview) widget and sample dashboard for viewing metrics and data from your [OctoPrint](http://octoprint.org) rig. This is developed against [OctoPi](https://github.com/guysoft/OctoPi).

##Installation

-	Clone (the repository)[]
-	Run the `scripts/deploy.sh` shell script, which will perform the needed actions to install this widget.
-	Restart Dashing to pick up the new changes.
-	Navigate to the newly installed octoprint dashboard in your browser, and revel in the dashboardy goodness of your octoprint rig.

###Required Widgets

I might decide to make this use multigraph if I ever get it working

---

##Configuration

The `octoprint_defaults.yaml` file tunes the behavior of the job. it is meant to provide you an example configuration of the configurable parameters. You are meant to create an `octoprint_ocerrides.yaml` file in the `conf.d` directory with your specific settings. This permits you to update the default configuration file automatically, while simultaneously maintaining a custom local configuration.
