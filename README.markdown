#![Icon](https://github.com/chetan51/sidestep/raw/master/media/icons/Sidestep-Main-Logo-48x48.png "Icon") Sidestep#

##_Say Hello to Sidestep_##

***The problem***

When you connect to the Internet through an unprotected wireless network, such as at a coffeeshop or an airport, where you don’t have to enter a security key, you’re putting yourself at risk.

Attackers connected to the same network can easily intercept your unencrypted traffic and log in as you to services such as Facebook, Amazon, and LinkedIn.

Try this simple Firefox add-on to see for yourself how serious the problem is and how easy it is for your privacy and security to be compromised.

***The solution***

When Sidestep detects you connecting to an unprotected wireless network, it automatically encrypts all of your Internet traffic and reroutes it through a secure connection to a server of your choosing, which acts as your Internet proxy. And it does all this in the background so that you don’t even notice it.

With Sidestep enabled, no one can eavesdrop on your traffic and impersonate you or see what you’re seeing as you browse the web.
How does it work?

The first time you run Sidestep, you give it the details of the proxy server that you want it to use to securely reroute your Internet traffic through. And that’s it.

![Welcome (main window)](https://github.com/chetan51/sidestep/raw/master/media/screenshots/Welcome.png "Welcome")

Now, every time you connect to the Internet, Sidestep checks to see if your connection is already secured by WPA wireless security - if it is, Sidestep does nothing. After all, there’s no point in rerouting your connection and using up bandwidth on your proxy server if your connection is already secure. However, if your wireless connection is open and unprotected, Sidestep connects to your proxy server using SSH and reroutes all your traffic through it. This technology is called an SSH Tunnel Proxy.

***In Geekspeak***

When you connect to an insecure network, Sidestep opens an SSH tunnel with the proxy server, and then sets the Mac OS X system-wide SOCKS proxy to use this SSH connection. And since most Mac applications (including browsers) use this system-wide proxy to connect to the Internet through, they will all end up using the encrypted SSH tunnel.

***Fighting Firesheep with fire***

Firesheep, the Firefox add-on mentioned above, made a huge wave in the computer security world when it was released. Using it, anyone with Firefox can sit in a coffeeshop and click one button to hijack the browsing sessions of other users around them.

Sidestep is the easiest solution to the problem made mainstream by Firesheep. Set it up once, and never worry about attacks like Firesheep ever again.

***Requirements***

Mac OS X 10.5+ required

***Project Homepage***

Got a question or comment regarding Sidestep?  Please stop by [chetansurpur.com](http://chetansurpur.com/projects/sidestep/) and let us know what you're thinking.
