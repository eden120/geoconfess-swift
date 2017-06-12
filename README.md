![GeoConfess Logo](Logo.png)

# GeoConfess

GeoConfess iOS app, an Uber style app for linking *penitents* and *priests*.

1. [Development Tools](#development-tools)
	- [Swift Coding Conventions](#swift-coding-conventions)
	- [Xcode and iOS Simulator Issues](#xcode-and-ios-simulator-issues)
2. [Backend](#backend)
3. [Testing](#testing)
	- [Test Accounts](#test-accounts)
	- [Test Locations](#test-locations)
	- [Test Mode](#test-mode)

## Development Tools

The recommended Xcode version is **7.3.1**. All app code is based on **Swift 2.2**. 

All dependencies are managed by [CocoaPods](https://cocoapods.org), version **1.0.0**.
The downloaded frameworks are stored in the `Pods` directory and *not* tracked by Git.
As such, you must run `pod install` after cloning the repo (or pulling in new code).

### Swift Coding Conventions 

Please configure your Xcode to the following settings: 

* Page guide at column: **90** 
* Prefer indent using: **Tabs**
* Tab width: **4**
* Automatically trim trailing whitespaces: **on**

All settings above are available at: *Xcode* > *Preferences...* > *Text Editing*.

### Xcode and iOS Simulator Issues

If your iOS Simulator is hanging  
[this](https://forums.developer.apple.com/thread/24274) might bring you some relief :-) 

Basically, some OS X apps (eg, *BetterSnapTool*, *Flexiglass*, *Upwork*, etc) 
seems to be conflicting with the iOS Simulator.
This issue is related to accessibility features in OS X.
This is a [known bug](http://www.openradar.me/23504761) since Xcode **7.1**. 
(If you need help fixing this, please talk to developer 
[pmattos](https://github.com/pmattos).)

If everything else fails, try a full reset:

	bin/reset-xcode-and-simulators
	
**Playground not running**. Check that you have *iPad Pro* simulator in your 
devices in Xcode. If not, add it via the *Devices* window. You may also need 
to restart Xcode.	

## Backend

Our backend API is documented [here](http://geoconfess.herokuapp.com/apidoc/V1.html).

Some useful scripts are available in the `bin` directory 
for playing with the backend (eg, `bin/show-user`).

The [Pusher](https://pusher.com) service is used for *realtime* notifications.

## Testing

Some useful information for testing the app follows.

### Test Accounts

Some handy accounts for testing:

	[
		{
			"id":       54,
			"role":     "user",
			"email":    "user@example.com",
			"password": "123456",
			"name":     "Example",
			"surname":  "User",
			"active":   true,
		},
		{
			"id":        68
			"role":      "user",
			"email":     "u@xx.xx",
			"password":  "123456",
			"name":      "XXX",
			"surname":   "USER",
			"active":    true,
			"favorites": 2
		},
		{
			"id" :      53,
			"role" :    "priest",
			"email":    "p@xx.xx",
			"password": "123456",
			"name":     "PPP"
			"surname":  "XXX",
			"active":   true,
			"spots":    2 # Cupertino @ (37.33, -122.03)
		},
		{
			"id":       55,
			"role":     "priest",
			"email":    "priest@example.com",
			"password": "123456",
			"name":     "Priest"
			"surname":  "Example",
			"active":   true,
			"spots":    4 # Paris @ (48.88, 2.35)
		},
		{
			"id":       1,
			"role":     "admin",
			"email":    "admin@example.com",
			"password": "1q2w3e4r",
			"name":     "MyName"
			"surname":  "Surname",
			"active":   true
		}
	]

For instance, for getting more info about one of these 
accounts, just type `bin/show-user <username> <password>`.

### Test Locations

Some handy test locations:

| Location                         | Latitude  | Longitude  |
| :------------------------------: | --------: | ---------: |
| Cupertino, California            |     37.33 |    -122.03 |
| Barra da Tijuca, Rio de Janeiro  |    -23.00 |     -43.33 |
| Rochechouart, Paris              |     48.88 |       2.35 |

### Test Mode

There is a built-in *test mode* with faster update times regarding geolocation updates, 
objects refresh, etc (eg, spots are reloaded every 9 seconds instead of 2 minutes).

To activate the test mode just tap *three times* on the GeoConfess logo 
*above* every app screen. Just repeat this gesture to deactivate it.   


