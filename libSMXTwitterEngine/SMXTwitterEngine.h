//
//  SMXTwitterEngine.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 The Lab, Telefonica UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMXTwitterEngine : NSObject

// Set this to allow users to select another account not in ACAccountStore
+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback;

// When posting a tweet, use the iOS5 Tweet Sheet
+ (void) setUseTweetComposeSheetIfPossible:(BOOL)useTweetComposeSheet;

// Posting Tweets
+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
+ (void) sendTweet:(NSString *)tweet andImage:(UIImage *)image withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

// Receiving Tweets
+ (void) streamTweetsWithHandler:(void (^)(NSDictionary *message, NSError *error))handler;

@end
