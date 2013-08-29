# CHANGELOG for application_procfile

This file is used to list changes made in each version of application_procfile.

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
