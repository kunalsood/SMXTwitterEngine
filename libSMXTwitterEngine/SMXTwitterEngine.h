//
//  SMXTwitterEngine.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 The Lab, Telefonica UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMXTwitterEngine : NSObject

// You only need to use this if your app supports iOS 4, or you want to allow other accounts not in ACAccountStore
+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback;

// iOS5 only
+ (void) setUseTweetComposeSheetIfPossible:(BOOL)useTweetComposeSheet;

// Posting Tweets
+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
+ (void) sendTweet:(NSString *)tweet andImage:(UIImage *)image withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

// Receiving Tweets
+ (void) streamTweetsWithHandler:(void (^)(NSDictionary *response, NSError *error))handler;

@end
