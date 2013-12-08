MemUp
=====
![Screenshot](http://i.imgur.com/BTViEOy.png)

Current memory usage shown in MB. Tap to MemUp!

An iOS NotificationCenter plugin offering a single-tap memory cleanup solution.  
Created using [iOSOpenDev](https://github.com/kokoabim/iOSOpenDev). Utilizing BigBoss' `freemem` executable at the core.

Now with a PrefernceLoaderBundle. But don't except too much functionality at this point :)

### Building requirements
* Jailbroken iOS device running iOS 5-6  
* Xcode and [iOSOpenDev](http://iosopendev.com/download/) installed  

### Installation from source
* Set `iOSOpenDevDevice` environment variable in Xcode build settings to the IP of your iOS device  
  
  ![Build settings](http://i.imgur.com/t8UpZ2N.png)  
* Setup key-based ssh authentication between build host and iOS device for automatic installation of package  
* Hit `Cmd-Shift-I`

### If you just want to install:
* Use the provided package and on the iOS device, run  
`$ sudo dpkg -i com.rub1k.MemUp_1.0-1_iphoneos-arm.deb; killall SpringBoard`  
* And of course you have to make it visible in NC by putting it in the list of displayed widgets in Preferences -> Notifications.
