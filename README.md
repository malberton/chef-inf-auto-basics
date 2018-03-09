## Chef Infrastructure Automation Basics Using Docker and Ubuntu

This repo is part of the following Chef Rally track:

[infrastructure automation track -> Learn the Chef basics module -> Ubuntu -> Docker](https://learn.chef.io/modules/learn-the-basics/ubuntu/docker#/)

What I used:
- Docker 17.12.0-ce-mac55
	- Container running Ubuntu:16.04
- OSX 10.13.3
- iTerm 2
---

### Starting Up Docker Container
1. Make sure Docker is installed, then in iTerm or Terminal navigate to the folder where you'll be storing your files

2. Pull the Ubuntu image you'd like to use. The official documentation uses 14.04 but I used 16.04

3. Run a container using that image

 	```bash
	# Step 2
	$ docker pull ubuntu:16.04

	# Step 3
	$ docker -it -v $(pwd):/root/chef-repo -p 8100:80 ubuntu:16.04 bash
		# -it runs an interactive container with a pseudoterminal allocated
		# -v $(pwd):/root/chef-repo mounts the current host directory to the container
		# -p 8100:80 maps port 8100 on the host to port 80 on the container
	```

4. You should be logged into the container now as the root user (`root@<container_ID>:`)
---

### Configure a Resource
1. Create a Chef recipe to print `hello world` to a file called `motd` in the `/tmp` directory
	```ruby
	# hello.rb
	file '/tmp/motd' do
	  content 'hello world'
	end
	```

2. Run the recipe locally
	```bash
	$ chef-client --local-mode hello.rb
	```

3. Run the recipe a second time to see that because the file already matches the output from the recipe, no changes will be made (i.e. idempotent)

4. Edit `hello.rb`
	```ruby
	# hello.rb
	file '/tmp/motd' do
	  content 'hello chef'
	end
	```

5. Run the recipe locally
	```bash
	$ chef-client --local-mode hello.rb
	```

6. This will produce a change in the 'motd' file we created previously, since the contents of the file differed from the recipe

7. Ensure that Chef will overwrite any external changes made to the file
	```bash
	$ echo 'hello-robots' > /tmp/motd
	$ chef-client --local-mode hello.rb
	```

8. The first line changes the contents of `motd` from `hello chef` to `hello robots`. Running the Chef client changed it back to `hello chef`

9. Remove the `motd` file via a recipe
	```ruby
	# goodbye.rb
	file '/tmp/motd' do
	  action :delete
	end
	```

10. Run the recipe
	```bash
	$ chef-client --local-mode goodbye.rb
	```

11. Ensure file was deleted (output should show that file does not exist)
	```bash
	$ more /tmp/motd
	```
---

### Configure a Package and Service

1. Write a recipe to update the apt cache daily
	```ruby
	# webserver.rb
	apt_update 'Update the apt cache daily' do
	  frequency 86_400 # 1 day measured in seconds. Ruby convention for large numbers is to use an underscore for readability
	  action :periodic
	end
	```

2. Install `Apache` as part of the `webserver.rb` recipe
	```ruby
	# webserver.rb
	package 'apache2' # The action :install is the implicit default and doesn't need to be specified
	```

3. Run the recipe. Since we are logged in as the root used in Docker, we don't need `sudo` privileges to install the package
	```bash
	$ chef-client --local-mode webserver.rb
	```

4. Enable and start Apache as part of the `webserver.rb` recipe, then run the recipe
	```ruby
	# webserver.rb
	service 'apache2' do
	  supports status: true     # Helps Chef determine if the apache2 service is running
	  action [:enable, :start]  # Enable and start the apache2 service
	end

	# Bash
	$ chef-client --local-mode webserver.rb
	```

5. Add a home page to see that our server is running and run the recipe
	```ruby
	# webserver.rb
	file '/var/www/html/index.html' do
	  content '
	  <html>
	    <body>
	      <h1>hello world</h1>
	    </body>
	  </html>
	  '
	end

	# Bash
	$ chef-client --local-mode webserver.rb
	```

6. Confirm website is running. In the container, run `curl localhost` (port 80 is default). On workstation, browse to `localhost:8100`. Recall that these ports were mapped as part of starting up the container
---

### Cookbooks

1. Make a new directory for cookbooks and generate a new cookbook
	```bash
	$ mkdir cookbooks
	$ chef generate cookbook cookbooks/learn_chef_apache2
	# This makes a new cookbook in the `cookbooks` folder named `learn_chef_apache2`
	```

2. This will have generated a series of files and folders. You can run the following to see the new output
	```bash
	$ apt-get install -y tree
	$ tree cookbooks
	```

3. Create an HTML template that will be referenced by your recipes. This will create `index.html.erb`
	```bash
	$ chef generate template cookbooks/learn_chef_apache2 index.html
	$ tree cookbooks
	```

4. Copy the HTML contents of `webserver.rb` over to the `index.html.erb` file in the `cookbooks/learn_chef_apache2/templates/` folder
 	```html
	<!-- index.html.erb -->
	<html>
	  <body>
	    <h1>hello world</h1>
	  </body>
	</html>
	```

5. Note that there is already a `recipes` folder with `default.rb`. Modify that with the following code
 	```ruby
	# default.rb
	apt_update 'Update the cache daily' do
	  frequency 86_400
	  action :periodic
	end

	package 'apache2'

	service 'apache2' do
	  supports status: true
	  action [:enable, :start]
	end

	file '/var/www/html/index.html' do
	  source 'index.html.erb'
	end
	```

6. Note that the code in `default.rb` is identical to `webserver.rb` except that the HTML content has been replaced with a reference to the `index.html.erb` file. You can run the cookbook
	```bash
	$ chef-client --local-mode --runlist 'recipe[learn_chef_apache2]'
	# This is the same as running a recipe, except we include the ``runlist flag
	# This allows us to specify as many recipes as we want from our cookbook
	# recipe[learn_chef_apache2] is the same as recipe[learn_chef_apache2::default]
	# The general form of this would be recipe[<COOKBOOK>::<RECIPE>]'
	```

7. To verify that everything is still working, re-run the `curl localhost` command or go to `localhost:8100` in your browser
