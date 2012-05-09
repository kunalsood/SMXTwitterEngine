//
//  SMXTwitterEngine.m
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "SMXTwitterEngine.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>

@interface SMXTwitterEngine ()

+ (void) useTwitterFrameworkToSendTweet:(NSString *)tweet completionHandler:(void (^)(id response, NSError *error))handler;
+ (void) useManualOauthToSendTweet:(NSString *)tweet completionHandler:(void (^)(id response, NSError *error))handler;

@end

@implementation SMXTwitterEngine

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(id response, NSError *error))handler
{
    if (NSClassFromString(@"TWRequest") != nil){
        [SMXTwitterEngine useTwitterFrameworkToSendTweet:tweet completionHandler:handler];
    } else {
        [SMXTwitterEngine useManualOauthToSendTweet:tweet completionHandler:handler];
    }
}

+ (void) useTwitterFrameworkToSendTweet:(NSString *)tweet completionHandler:(void (^)(id response, NSError *error))handler
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    NSArray *accounts = [accountStore accountsWithAccountType:[accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]];
    
    if (accounts.count == 0){
        [self useManualOauthToSendTweet:tweet completionHandler:handler];
    } else {
        
    }
}

+ (void) useManualOauthToSendTweet:(NSString *)tweet completionHandler:(void (^)(id response, NSError *error))handler
{
    
}

@end
