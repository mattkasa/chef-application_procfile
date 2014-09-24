application_procfile Cookbook
=============================
This cookbook installs initscripts and monitrc files for the different process types specified in your application's Procfile.

Requirements
------------
#### cookbooks
- `application` - application_procfile needs the application cookbook to discover a Procfile.
- `monit` - application_procfile needs the monit cookbook to configure services under monit.

#### gems
- `foreman` - application_procfile uses the foreman gem's Procfile parser.

Usage
-----
#### <cookbook>/metadata.rb:
```ruby
depends 'application_procfile'
```

#### <cookbook>/recipes/default.rb:
```ruby
include_recipe 'application_procfile'

application 'someapp' do
  ...
  procfile do
    web node[:someapp][:processes][:web] || 1, :reload => 'USR2', :health_check => { :path => '/system/status', :timeout => 10, :unhealthy => 10, :action => :alert }, :limit => { :totalmem => '512 MB', :unhealthy => 10 }
    worker node[:someapp][:processes][:worker] || 2, :limit => { :totalmem => '192 MB' }
  end
end
```

This will run a default of 1 web and 2 workers for a Procfile that looks like:

```
web: bundle exec unicorn -c ./config/unicorn.rb
worker: bundle exec rake resque:work
```

If you provide a port number via a node attribute `node[:app][:port]` then it will be incremented automatically and made available to your Procfile commands:

```
web: bundle exec thin start -p $PORT
```

Any output to stderr or stdout from your processes will be logged to files like:

```
/var/log/someapp/web.log
/var/log/someapp/worker.log
```

To restart your workers:

```bash
touch /var/local/someapp/worker.restart
```

The `reload` option specifies an optional signal that can be sent to processes to gracefully reload them by doing:

```bash
touch /var/local/someapp/web.reload
```

If the process is unicorn a HUP and USR2 combination will be used automatically, with no need for the `reload` option.

To properly support reloads for unicorn processes, a unicorn.rb with before_fork, correct paths and worker numbers will be installed in the shared directory and will include your `config/unicorn.rb` if you have one.

You can specify resource limits with the `:limit` option, such as `:mem`, `:totalmem`, `:cpu`, `:totalcpu`, or `:children`.

For `:mem` and `:totalmem` the value is the maximum allowable memory for the process or the process and all it's children, respectively, as B, KB, MB, GB, or %.  (eg. `:limit => { :totalmem => '512 MB' }`)

For `:cpu`, and `:totalcpu` the value is the maxmimum allowable CPU usage for the process or the process and all it's children, respectively, as %.  (eg. `:limit => { :totalcpu => '90%' }`)

For `:children` the value is the maximum number of child processes allowed for the process.  (eg. `:limit => { :children => 10 }`)

Within `:limit` you can specify the action to be taken `:alert`, `:restart`, or `:stop` when any of the limits are exceeded.  (eg. `:limit => { :cpu => '25%', :action => :alert }`)

You can also specify the number of times the limits must exceed their values before taking action using `:unhealthy`.  (eg. `:limit => { :mem => '10%', :unhealthy => 10 }`)

You can specify a health check with the `:health_check` option as long as the port your service is listening on is accessible via node attribute as `node[:app][:port]` or you specify a `:port` in your health check.  (eg. `:health_check => { :port => 8080, :path => '/system/status', :timeout => 10, :unhealthy => 10, :action => :alert }`)

Contributing
------------
1. Fork the repository on Github
2. Create a named feature branch (like `add_component_x`)
3. Write your change
4. Write tests for your change (if applicable)
5. Run the tests, ensuring they all pass
6. Submit a Pull Request using Github

License and Authors
-------------------
Author:: Javier Muniz <javier@granicus.com>
Author:: Matt Kasa <mattk@granicus.com>

Copyright 2014, Granicus Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
