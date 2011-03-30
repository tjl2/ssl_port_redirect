# SSL Port Redirect 

This cookbook is provided to enable client IP addresses to be available to your application, rather than the address of the server that proxied the request.

## History

Our current cluster architecture ([outlined in our AppCloud docs](http://docs.engineyard.com/appcloud/guides/environments/home#cluster-architechture)) has HAProxy configured on your application master instance on port 443. This will then proxy requests out to Nginx on all other application servers on port 444 as necessary. Unfortunately, as HAProxy cannot decrypt your SSL traffic, we have to just pass the TCP traffic over to Nginx and are not able to add a 'forwarded-for' header into the request.

## Redirecting port 443

Using iptables, this cookbook will redirect all port 443 traffic onto port 444, directly to Nginx and bypassing HAProxy. Nginx will then forward requests back in to HAProxy on port 80, just as a normal non-SSL request would behave. This then allows the Nginx to add a header to the request, after decrypting it.
Please be aware that this setup is going to make your application master instance be responsible for decrypting *all* SSL traffic, which depending on your usage, may lead to causing increased CPU load on the applicaiton master.

## Compatibility with Passenger

**Please note** that if you are using Passenger (version 2 or 3) as your stack, you must also download and install [this rack middleware](https://github.com/tjl2/rack_forwarded_for_override) for your app before following the instructions below.

## Usage instructions

First, make sure that you have SSL enabled for an app in the environment where this recipe is going to be run, via the SSL tab on the dashboard.

Then add this recipe to your cookbooks and require it, as per the docs at [http://docs.engineyard.com/appcloud/howtos/customizations/custom-chef-recipes](http://docs.engineyard.com/appcloud/howtos/customizations/custom-chef-recipes)
