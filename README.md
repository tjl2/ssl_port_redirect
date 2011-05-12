# SSL Port Redirect 

This cookbook is provided to enable client IP addresses to be available to your application, rather than the address of the server that proxied the request.

## History

Our current cluster architecture ([outlined in our AppCloud docs](http://docs.engineyard.com/appcloud/guides/environments/home#cluster-architechture)) has HAProxy configured on your application master instance on port 443. This will then proxy requests out to Nginx on all other application servers on port 444 as necessary. Unfortunately, as HAProxy cannot decrypt your SSL traffic, we have to just pass the TCP traffic over to Nginx and are not able to add a 'forwarded-for' header into the request.

## Redirecting port 443

Using iptables, this cookbook will redirect all port 443 traffic onto port 444, directly to Nginx and bypassing HAProxy. Nginx will then forward requests back in to HAProxy on port 80, just as a normal non-SSL request would behave. This then allows the Nginx to add a header to the request, after decrypting it.
Please be aware that this setup is going to make your application master instance be responsible for decrypting *all* SSL traffic, which depending on your usage, may lead to causing increased CPU load on the applicaiton master.

## Things to be aware of
### Compatibility with Passenger

**Please note** that if you are using Passenger (version 2 or 3) as your stack, you must also download and install [this rack middleware](https://github.com/tjl2/rack_forwarded_for_override) for your app before following the instructions below.

### Redirects to HTTPS
If you are redirecting HTTP requests to HTTPS in Nginx, rewrites that check the protocol will fail (as all requests are decrypted before being proxied to your app instances). If you need to do this kind of redirection, then you can check for the presence of the EY-SSL-Fix header like this:

    if ( $http_ey_ssl_fix != 'Enabled') { 
      rewrite ^/(.*) https://$host/$1 permanent; 
    }


### Increased Load on App Master
Now that all SSL traffic is being decrypted on the app master instance, you may find that the CPU load on this instance increases. While this should be negligible, if you force all your traffic through HTTPS, then please be aware that this extra load may become noticeable and may slow down response times of your app.


## Usage instructions

First, make sure that you have SSL enabled for an app in the environment where this recipe is going to be run, via the SSL tab on the dashboard.

Then add this recipe to your cookbooks and require it, as per the docs at [http://docs.engineyard.com/appcloud/howtos/customizations/custom-chef-recipes](http://docs.engineyard.com/appcloud/howtos/customizations/custom-chef-recipes)
