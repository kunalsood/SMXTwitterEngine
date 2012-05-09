# SMXTwitterEngine

After being annoyed by the complexity of other Twitter libraries for iOS, I built this. It only
supports posting a Tweet, and I've no intention of supporting the other capabilities in Twitter.

It uses iOS5's Twitter framework when running on a device that supports it, but falls back
to good a old fashioned UIWebView if the device is running 4.x or there are no Twitter accounts
configured in iOS.

If you only want to use it on iOS5, it's really simple:

``` objc
[SMXTwitterEngine sendTweet:@"This is a tweet" withCompletionHandler:^(NSDictionary *response, NSError *error){
	NSLog(@"Response: %@", response);
	NSLog(@"Error: %@", error);
}];
```

Want to attach an image? Easy:

``` objc
[SMXTwitterEngine sendTweet:@"This is a tweet" andImage:myImage withCompletionHandler:^(NSDictionary *response, NSError *error){
	NSLog(@"Response: %@", response);
	NSLog(@"Error: %@", error);
}];
```

If you're planning on running on devices running 4.x, you'll also need:

``` objc
[SMXTwitterEngine setConsumerKey:@"KEY" consumerSecret:@"SECRET" callback:@"CALLBACK"];
```

You'll need to get your consumer key, consumer secret and callback set up [here](http://dev.twitter.com/apps). 
Don't forget to make the application "Read & Write".

## Installing

First, grab the submodules:

```
git submodule update --init
```

Then, drag the SMXTwitterEngine Xcode project into your project. Add libSMXTwitterEngine as a dependency,
and make sure to link against it.

Add -ObjC and -all_load to your "Other Linker Flags".

You'll also need to link against Twitter.framework and Accounts.framework. If you plan to support iOS 4.x, you'll
need to make sure those are optional frameworks (weakly linked).

Finally, make sure that THWebController.bundle is in your "Copy Bundle Resources" Build Phase.

## Demo

Have a look at the example project for a working demo.

## ARC

As much as I'd love to support ARC, requiring iOS 4.0 support means I can't :(

## iOS 3

Since iOS 3 doesn't support blocks, it is currently not supported. Feel free to issue a pull request ;)