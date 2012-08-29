//
//  SMXTwitterEngine.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 The Lab, Telefonica UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMXTwitterEngine : NSObject

// You only need to use this if your app supports iOS 4
+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback;
+ (void) setUseTweetComposeSheetIfPossible:(BOOL)useTweetComposeSheet;

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
+ (void) sendTweet:(NSString *)tweet andImage:(UIImage *)image withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
+ (void) streamTweetsWithHandler:(void (^)(NSDictionary *response, NSError *error))handler;

@end
