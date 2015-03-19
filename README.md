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
