//
//  SMXTwitterEngine.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMXTwitterEngine : NSObject

// You only need to use this if your app supports iOS 4
+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback;

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

@end
