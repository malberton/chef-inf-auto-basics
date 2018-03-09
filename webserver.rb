apt_update 'Update the cache daily' do
  frequency 86_400
  action :periodic
end

package 'apache2' # Don't need to specify an action because :install is the default for the `package` resource

service 'apache2' do
  supports status: true
  action [:enable, :start]
end

file '/var/www/html/index.html' do
  content '
  <html>
    <body>
      <h1>hello world</h1>
    </body>
  </html>'
end
