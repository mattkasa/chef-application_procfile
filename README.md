application_procfile Cookbook
=============================
This cookbook installs initscripts and monitrc files for the different process types specified in your application's Procfile.

Requirements
------------
#### cookbooks
- `application` - application_procfile needs the application cookbook to discover a Procfile.

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
    web node[:someapp][:processes][:web] || 1, :reload => 'USR2'
    worker node[:someapp][:processes][:worker] || 2
  end
end
```

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
Author:: Matt Kasa <mattk@granicus.com>

Copyright 2013, Granicus Inc.

This file is part of application_procfile.

application_procfile is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

application_procfile is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with application_procfile.  If not, see <http://www.gnu.org/licenses/>.
