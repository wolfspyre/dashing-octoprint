#Dashing-OctoPrint

####A templatized 3D printing dashboard

This aims to be a [Dashing](http://shopify.github.io/dashing/#overview) widget and sample dashboard for viewing metrics and data from your [OctoPrint](http://octoprint.org) rig. This is developed against [OctoPi](https://github.com/guysoft/OctoPi).

##Installation

-	Clone (the repository)[]
-	Create a `conf.d` directory outside your dashboard's installation, so that it is outside the webserver's reach.
-	Symlink `octoprint_defaults.yaml` into the `conf.d` directory
-	Populate the `octoprint_overrides.yaml` file in the `conf.d` directory.
-	Symlink `widgets/octoprint` to your widgets directory `DASHBOARD_INSTALL_PATH/widgets/octoprint`
-	Symlink `jobs/octoprint`

###Required Widgets I might decide to make this use multigraph if I ever get it working

---

##Configuration

The `octoprint_defaults.yaml` file tunes the behavior of the job. it is meant to provide you an example configuration of the configurable parameters. You are meant to create an `octoprint_ocerrides.yaml` file in the `conf.d` directory with your specific settings. This permits you to update the default configuration file automatically, while simultaneously maintaining a custom local configuration.
