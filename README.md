# SMXTwitterEngine

After being annoyed by the complexity of other Twitter libraries for iOS, I built this. It supports
posting a tweet, and receiving a user's stream.

It uses iOS5's Twitter framework when running on a device that supports it, but falls back
to good a old fashioned UIWebView if there are no Twitter accounts configured in iOS.

It's really simple to use:

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

If you want to allow users to choose an account not in their Twitter settings:

``` objc
[SMXTwitterEngine setConsumerKey:@"KEY" consumerSecret:@"SECRET" callback:@"CALLBACK"];
```

You'll need to get your consumer key, consumer secret and callback set up [here](http://dev.twitter.com/apps). 
Don't forget to make the application "Read & Write".

Would you rather use a Tweet Sheet on iOS 5 if possible? Easy:

``` objc
[SMXTwitterEngine setUseTweetComposeSheetIfPossible:YES];
```

NOTE: Using a Tweet sheet will return an empty NSDictionary to your completion handler, since iOS doesn't make any
information about the posted tweet available.

Want to receive a stream of tweets?

```objc
[SMXTwitterEngine streamTweetsWithHandler:^(NSDictionary *object, NSError *error) {
	NSLog(@"Object: %@", object);
}];
```

That's it! SMXTwitterEngine will handle all authentication for you, so you don't need to worry about a thing!


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

Add "SMXTwitterEngine" to your Header Search Paths, and then make sure that THWebController.bundle is in your 
"Copy Bundle Resources" Build Phase.

Finally:

```objc
#import <libSMXTwitterEngine/SMXTwitterEngine.h>
```

And you're good to go!

## Demo

Have a look at the example project for a working demo.


## iOS 4

I decided to remove iOS 4 support from SMXTwitterEngine while adding support for the streaming API.
This was mostly because of the overhead of having another JSON parser in the framework. Now, it uses
NSJSONSerialization for simplicity.

## iOS 3

Since iOS 3 doesn't support blocks, it is currently not supported. Feel free to issue a pull request ;)