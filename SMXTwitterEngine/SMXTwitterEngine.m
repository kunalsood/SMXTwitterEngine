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
#import "UIAlertView+MKBlockAdditions.h"
#import "SA_OAuthTwitterEngine.h"
#import "SA_OAuthTwitterController.h"

@interface SMXTwitterEngine () {
}

+ (void) useTwitterFrameworkToSendTweet:(NSString *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
+ (void) useManualOauthToSendTweet:(NSString *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;


+ (void) useAccount:(ACAccount *)account toSendTweet:(NSString *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

@end

@interface SMXTwitterEngineHandler : NSObject <SA_OAuthTwitterEngineDelegate, SA_OAuthTwitterControllerDelegate>

@property (nonatomic) BOOL done;
@property (nonatomic, retain) NSError *error;

- (id) initWithPresentationController:(id)viewController tweet:(NSString *)tweet;

@end

@implementation SMXTwitterEngine

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
{
    if (NSClassFromString(@"TWRequest") != nil){
        [SMXTwitterEngine useTwitterFrameworkToSendTweet:tweet completionHandler:handler];
    } else {
        [SMXTwitterEngine useManualOauthToSendTweet:tweet completionHandler:handler];
    }
}

+ (void) useTwitterFrameworkToSendTweet:(NSString *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    
    [accountStore requestAccessToAccountsWithType:[accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter] 
                            withCompletionHandler:^(BOOL granted, NSError *error){
                                if (granted){
                                    NSArray *accounts = [accountStore accountsWithAccountType:[accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]];
                                    
                                    if (accounts.count == 0){
                                        // No accounts set up. Let's fall back to OAuth
                                        [self useManualOauthToSendTweet:tweet completionHandler:handler];
                                    } else {
                                        
                                        if (accounts.count == 1){
                                            // One account set up. Let's use that.
                                            [SMXTwitterEngine useAccount:[accounts objectAtIndex:0] toSendTweet:tweet completionHandler:handler];
                                        } else {
                                            // More than one account set up. Let's ask which one we should use...
                                            NSArray *titles = [accounts valueForKeyPath:@"accountDescription"];
                                            
                                            dispatch_async(dispatch_get_main_queue(), ^(){
                                                [UIAlertView alertViewWithTitle:NSLocalizedString(@"Choose a Twitter account", @"Choose a Twitter account alert title") 
                                                                        message:nil
                                                              cancelButtonTitle:NSLocalizedString(@"Cancel", @"Choose a Twitter account alert cancel button") 
                                                              otherButtonTitles:titles 
                                                                      onDismiss:^(int buttonIndex){
                                                                          [SMXTwitterEngine useAccount:[accounts objectAtIndex:buttonIndex] toSendTweet:tweet completionHandler:handler];
                                                                      }
                                                                       onCancel:^(){
                                                                           handler(nil, [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:101 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User Cancelled", @"User Cancelled error message") forKey:NSLocalizedDescriptionKey]]);
                                                                       }
                                                 ];

                                            });                                            
                                        }
                                        
                                    }
                                } else {
                                    if (error == nil){
                                        error = [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:403 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User did not allow access to Twitter accounts", @"User did not allow access to Twitter accounts error message") forKey:NSLocalizedDescriptionKey]];
                                    }
                                    
                                    handler(nil, error);
                                }
                            }
     ];
}

+ (void) useAccount:(ACAccount *)account toSendTweet:(NSString *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    TWRequest *twitterRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:@"http://api.twitter.com/1/statuses/update.json"] 
                                                    parameters:[NSDictionary dictionaryWithObject:tweet forKey:@"status"] 
                                                 requestMethod:TWRequestMethodPOST];
    [twitterRequest setAccount:account];
    
    [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
        NSError *jsonError = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
        
        if (jsonError){
            handler(nil, [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:102 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Error parsing response from Twitter", @"Error parsing response from Twitter error message") forKey:NSLocalizedDescriptionKey]]);
        } else {
            handler(responseDictionary, nil);
        }
    }];
}

+ (void) useManualOauthToSendTweet:(NSString *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    NSLog(@"Manually sending tweet");
    
    
}

+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback
{
    [[NSUserDefaults standardUserDefaults] setObject:consumerKey forKey:@"SMXTwitterEngineConsumerKey"];
    [[NSUserDefaults standardUserDefaults] setObject:consumerSecret forKey:@"SMXTwitterEngineConsumerSecret"];
    [[NSUserDefaults standardUserDefaults] setObject:callback forKey:@"SMXTwitterEngineCallback"];
}

@end


@implementation SMXTwitterEngineHandler

@synthesize done, error;

- (id) initWithPresentationController:(id)viewController tweet:(NSString *)tweet
{
    if (self = [super init]){
        
    }
    
    return self;
}

@end