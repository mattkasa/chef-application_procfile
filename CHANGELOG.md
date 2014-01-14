# CHANGELOG for application_procfile

This file is used to list changes made in each version of application_procfile.

## 0.3.22

* Add DSL for monit resource limits

## 0.3.21

* Add current_release helper method

## 0.3.20

* Abandon instance variable pointing to ProcfileHelpers.instance

## 0.3.19

* Try new_resource instead of @new_resource

## 0.3.18

* Try setting ProcfileHelpers attributes from before_compile

## 0.3.17

* Instantiate path/name/node for ProcfileHelpers in provider

## 0.3.16

* Set ProcfileHelpers new_resource to @application in initialize

## 0.3.15

* Make ProcfileHelpers a singleton

## 0.3.14

* Move new_resource and node initialization to attributes set from action blocks

## 0.3.13

* Refactor ProcfileHelpers as a class

## 0.3.12

* Include ProcfileHelpers in the scope of the provider so it has access to node and new_resource

## 0.3.11

* Move helper methods into ProcfileHelpers module

## 0.3.10

* Try not overlapping namespaces

## 0.3.9

* Try include instead of extend since we are in an instance of Chef::Provider

## 0.3.8

* Refactor library methods to not pass things around and move DSL wrappers to provider

## 0.3.7

* Pass new_resource to library helper methods

## 0.3.6

* Pass node to environment_attributes call

## 0.3.5

* Fix environment_attributes call

## 0.3.4

* Namespace helper methods inside Helpers module

## 0.3.3

* Call helper methods with self from within helpers

## 0.3.2

* Put helper methods inside Chef Application namespace

## 0.3.1

* Put helper methods inside Chef namespace

## 0.3.0

* Move protected methods to library as helper methods

## 0.2.7

* Perform lock and pid file migration during before_deploy

## 0.2.6

* Ensure enclosing lock directory exists

## 0.2.5

* Move lock and pid files to /var/local since /var/run and /var/lock are tmpfs mounts in ubuntu

## 0.2.4

* Move directives in unicorn.rb so they can be overridden by the application

## 0.2.3

* Remove unicorn start context hack

## 0.2.2

* Fix issue with PATH during environment reload

## 0.2.1

* Move methods back out of libraries until we find a pattern that works

## 0.2.0

* Refactor library methods and add more Unicorn magic

## 0.1.48

* Fix working directory used in BUNDLE_GEMFILE

## 0.1.47

* Try updating all the application sub-resource environments

## 0.1.45

* Move application environment population to before_compile

## 0.1.45

* Add BUNDLE_GEMFILE to unicorn.rb to support zero-downtime deploys

## 0.1.44:

* Remove unnecessary environment update

## 0.1.43:

* Use application environment instead of ENV

## 0.1.42:

* Remove PATH_PREFIX prepend from ENV

## 0.1.41:

* Use PATH_PREFIX instead of PATH to avoid overriding PATH

## 0.1.40:

* Treat PATH from application environment as an append

## 0.1.39:

* Use PATH from application environment

## 0.1.38:

* Add PATH to environment

## 0.1.37:

* Reload processes after environment changes

## 0.1.36:

* Fix env_path

## 0.1.35:

* Add support for reloading the environment

## 0.1.34:

* Fix unicorn.rb path preservation

## 0.1.33:

* Fix unicorn.rb path replacement

## 0.1.32:

* Add path to shared/unicorn.rb even if -c/--config-file is missing, otherwise preserve old value in shared/unicorn.rb

## 0.1.31:

* Only load unicorn.rb if it exists (this might be important)

## 0.1.30:

* Use instance_eval instead of require for unicorn.rb

## 0.1.29:

* Write static require path for unicorn.rb

## 0.1.28:

* Fix require path for unicorn.rb

## 0.1.27:

* Fix bug in create_lock_file and remove duplicate exports from initscripts

## 0.1.26:

* Update initscripts and monit configs from before_deploy

## 0.1.25:

* Fix unicorn reload path and monitrc paths

## 0.1.24:

* Fix unicorn.rb application path

## 0.1.23:

* Fix application paths

## 0.1.22:

* Add unicorn reload block to before_restart

## 0.1.21:

* Use static owner/group for unicorn.rb template

## 0.1.20:

* Put static template block in before_restart and before_deploy

## 0.1.19:

* Export node attributes from node[:application_name][:env]

## 0.1.18:

* Fix paths in monitrc

## 0.1.17:

* Fix absolute paths

## 0.1.16:

* Write unicorn.rb from both before_deploy and before_restart to correct issues with Procfile not being available

## 0.1.15:

* Assume process type web for unicorn

## 0.1.14:

* Upgrade for application >= 3.0.0 and fix unicorn.rb creation in before_deploy

## 0.1.13:

* Refactor procfile provider and add unicorn.rb template

## 0.1.12:

* Fix start syntax and depends on reload in monitrc

## 0.1.11:

* Remove monit restart

## 0.1.10:

* Touch reload files in restart_command and restart monit :delayed

## 0.1.9:

* Run touch on reload files from after_restart

## 0.1.8:

* Use local variable for new_resource

## 0.1.7:

* Reload monit in restart_command and add :delayed touch to reload files

## 0.1.6:

* Remove monit restart

## 0.1.5:

* Add delayed restart of monit and force UTF-8 in application environment

## 0.1.4:

* Use resource name to load node attributes into the environment instead of sourcing /etc/profile

## 0.1.3:

* Use resource name in restart/reload file names in monit to help avoid naming collisions

## 0.1.2:

* Now use reload to restart services for processes supporting zero-downtime deploys

## 0.1.1:

* Now explicitly restarts services

## 0.1.0:

* Initial release of application_procfile

- - -
Check the [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) for help with Markdown.

The [Github Flavored Markdown page](http://github.github.com/github-flavored-markdown/) describes the differences between markdown on github and standard markdown.
