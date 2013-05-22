name             'application_procfile'
maintainer       'Granicus Inc.'
maintainer_email 'Matt Kasa <mattk@granicus.com>'
license          'agplv3'
description      'Installs/Configures services from an application\'s Procfile'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'
recipe           'procfile', 'Installs foreman gem to use for parsing Procfiles'
depends          'application'
depends          'monit'
