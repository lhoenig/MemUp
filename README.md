MemUp
=====
![Looks like this](http://i.imgur.com/JEX5sez.png)

Current memory usage shown in MB. Tap to MemUp!

An iOS NotificationCenter plugin offering a one-click memory cleanup solution.  
Created using [iOSOpenDev](https://github.com/kokoabim/iOSOpenDev).

### Building requirements
* Jailbroken iOS device running iOS 6 (not tested on iOS 7 because there is no JB yet)  
* Xcode and [iOSOpenDev](https://iosopendev.com) installed  

### Installation
* iOSOpenDevDevice environment variable in Xcode build settings to the IP of your iOS device  
* Setup key-based ssh authentication between build host and iOS device for automatic installation of package  
* Hit `Cmd-Shift-I`

### If you just want to install:
* Use the provided package and on the iOS device, run  
`$ sudo dpkg -i com.rub1k.MemUp_1.0-1_iphoneos-arm.deb; killall SpringBoard`  
And of course you have to make it visible in NC by putting it in then list of displayed Widgets in Preferences -> Notifications.
