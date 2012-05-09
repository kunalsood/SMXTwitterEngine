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

#import "OADataFetcher.h"
#import "OAToken.h"

#import "THWebController.h"
#import "JSONKit.h"

#import "Tweet.h"

@interface SMXTwitterEngine () {
}

+ (void) useTwitterFrameworkToSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
+ (void) useManualOauthToSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;


+ (void) useAccount:(ACAccount *)account toSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

@end

@interface SMXTwitterEngineHandler : NSObject

@property (nonatomic, retain) Tweet *tweet;
@property (nonatomic) BOOL done;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, strong) id presentationViewController;
@property (nonatomic, strong) OAConsumer *consumer;
@property (nonatomic, strong) OAToken *accessToken;
@property (nonatomic, strong) NSDictionary *responseDictionary;

- (id) initWithPresentationController:(id)viewController tweet:(Tweet *)tweet;
- (void) postTweet;

@end

@interface SMXTwitterWebViewController : THWebController
@property (nonatomic, assign) id twitterDelegate;
@end

@implementation SMXTwitterEngine

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
{
    Tweet *t = [[Tweet alloc] init];
    t.tweet = tweet;
    
    if (NSClassFromString(@"TWRequest") != nil){
        [SMXTwitterEngine useTwitterFrameworkToSendTweet:t completionHandler:handler];
    } else {
        [SMXTwitterEngine useManualOauthToSendTweet:t completionHandler:handler];
    }
}

+ (void) sendTweet:(NSString *)tweet andImage:(UIImage *)image withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    
}

+ (void) useTwitterFrameworkToSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
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
                                                                           dispatch_async(dispatch_get_main_queue(), ^(){
                                                                               handler(nil, [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:101 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User Cancelled", @"User Cancelled error message") forKey:NSLocalizedDescriptionKey]]);
                                                                           });
                                                                       }
                                                 ];

                                            });                                            
                                        }
                                        
                                    }
                                } else {
                                    if (error == nil){
                                        error = [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:403 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User did not allow access to Twitter accounts", @"User did not allow access to Twitter accounts error message") forKey:NSLocalizedDescriptionKey]];
                                    }
                                    dispatch_async(dispatch_get_main_queue(), ^(){
                                        handler(nil, error);
                                    });
                                }
                            }
     ];
}

+ (void) useAccount:(ACAccount *)account toSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    TWRequest *twitterRequest = [[[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"] 
                                                    parameters:[NSDictionary dictionaryWithObject:tweet.tweet forKey:@"status"] 
                                                 requestMethod:TWRequestMethodPOST] autorelease];
    [twitterRequest setAccount:account];
    
    [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
        NSError *jsonError = nil;
        NSDictionary *responseDictionary = [[JSONDecoder decoder] objectWithData:responseData];
        
        if (jsonError){
            dispatch_async(dispatch_get_main_queue(), ^(){
                handler(nil, [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:102 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"Error parsing response from Twitter", @"Error parsing response from Twitter error message") forKey:NSLocalizedDescriptionKey]]);
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(){
                handler(responseDictionary, nil);
            });
        }
    }];
}

+ (void) useManualOauthToSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{   
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^(){
        SMXTwitterEngineHandler *engine = [[[SMXTwitterEngineHandler alloc] initWithPresentationController:[[[UIApplication sharedApplication] keyWindow] rootViewController] tweet:tweet] autorelease];
        
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!engine.done);
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            handler(engine.responseDictionary, engine.error);
        });
    });
}

+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback
{
    [[NSUserDefaults standardUserDefaults] setObject:consumerKey forKey:@"SMXTwitterEngineConsumerKey"];
    [[NSUserDefaults standardUserDefaults] setObject:consumerSecret forKey:@"SMXTwitterEngineConsumerSecret"];
    [[NSUserDefaults standardUserDefaults] setObject:callback forKey:@"SMXTwitterEngineCallback"];
}

@end


@implementation SMXTwitterEngineHandler

@synthesize done, error, presentationViewController, accessToken, consumer, tweet, responseDictionary;

- (id) initWithPresentationController:(id)viewController tweet:(Tweet *)aTweet
{
    if (self = [super init]){
        
        self.presentationViewController = viewController;
        self.tweet = aTweet;
        
        NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineConsumerKey"];
        NSString *secret = [[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineConsumerSecret"];
        
        
        self.consumer = [[[OAConsumer alloc] initWithKey:key
                                                        secret:secret] autorelease];
        
        OAToken *token = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"SMXTwitterEngineAccessToken" prefix:nil] autorelease];
        
        if (token.isValid){
            self.accessToken = token;
            [self postTweet];
        } else {
            
            OADataFetcher *fetcher = [[[OADataFetcher alloc] init] autorelease];
            
            NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
            
            OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                           consumer:consumer
                                                                              token:nil
                                                                              realm:nil
                                                                  signatureProvider:nil] autorelease];
            
            [request setHTTPMethod:@"POST"];
            
            [fetcher fetchDataWithRequest:request 
                                 delegate:self
                        didFinishSelector:@selector(requestTokenTicket:didFinishWithData:)
                          didFailSelector:@selector(requestTokenTicket:didFailWithError:)];
        }
    }
    
    return self;
}

- (void) requestTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed)
    {
        NSString *responseBody = [[[NSString alloc] initWithData:data 
                                                       encoding:NSUTF8StringEncoding] autorelease];
        
        self.accessToken = [[[OAToken alloc] initWithHTTPResponseBody:responseBody] autorelease];
        
        NSString *address = [NSString stringWithFormat:
                             @"https://api.twitter.com/oauth/authorize?oauth_token=%@",
                             self.accessToken.key];
        
        NSURL *url = [NSURL URLWithString:address];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            SMXTwitterWebViewController *webViewController = [[SMXTwitterWebViewController alloc] init];
            [webViewController setTwitterDelegate:self];
            [webViewController openURL:url];
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
            [self.presentationViewController presentModalViewController:navigationController animated:YES];
            [webViewController release];
            [navigationController release]; 
        });
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[[request URL] absoluteString] rangeOfString:[[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineCallback"]].length > 0){
        
        NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
                
        NSArray *urlPieces = [[[request URL] absoluteString] componentsSeparatedByString:@"?"];
        
        NSArray *params = [[urlPieces objectAtIndex:1] componentsSeparatedByString:@"&"];
        
        for (NSString *p in params){
            NSArray *pieces = [p componentsSeparatedByString:@"="];
            [parameters setObject:[pieces objectAtIndex:1] forKey:[pieces objectAtIndex:0]];
        }
                        
        [self.accessToken setVerifier:[parameters objectForKey:@"oauth_verifier"]];
        
        OADataFetcher *fetcher = [[OADataFetcher alloc] init];
        
        NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
                
        OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                       consumer:self.consumer
                                                                          token:self.accessToken
                                                                          realm:nil
                                                              signatureProvider:nil] autorelease];
        
        [request setHTTPMethod:@"POST"];
        
        [fetcher fetchDataWithRequest:request 
                             delegate:self
                    didFinishSelector:@selector(accessTokenTicket:didFinishWithData:)
                      didFailSelector:@selector(accessTokenTicket:didFailWithError:)];
        
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.presentationViewController dismissModalViewControllerAnimated:YES];
        });
        
        return NO;
    }
    return YES;
}

- (void) accessTokenTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
    if (ticket.didSucceed)
    {
        NSString *responseBody = [[[NSString alloc] initWithData:data 
                                                       encoding:NSUTF8StringEncoding] autorelease];
        
        self.accessToken = [[[OAToken alloc] initWithHTTPResponseBody:responseBody] autorelease];
        [self.accessToken storeInUserDefaultsWithServiceProviderName:@"SMXTwitterEngineAccessToken" prefix:nil];
        [self postTweet];
    }
}

- (void) postTweet
{        
    OADataFetcher *fetcher = [[OADataFetcher alloc] init];
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1/statuses/update.json"]];
    
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
                                                                   consumer:self.consumer
                                                                      token:self.accessToken
                                                                      realm:nil
                                                          signatureProvider:nil] autorelease];
    
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[[NSString stringWithFormat:@"status=%@", [self.tweet.tweet encodedURLParameterString]] dataUsingEncoding:NSUTF8StringEncoding]];
    
    [fetcher fetchDataWithRequest:request 
                         delegate:self
                didFinishSelector:@selector(apiTicket:didFinishWithData:)
                  didFailSelector:@selector(apiTicket:didFailWithError:)];
}

- (void) apiTicket:(OAServiceTicket *)ticket didFinishWithData:(NSData *)data
{
    self.responseDictionary = [[JSONDecoder decoder] objectWithData:data];
    
    if ([self.responseDictionary objectForKey:@"error"] != nil){
        self.error = [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:103 userInfo:[NSDictionary dictionaryWithObject:[self.responseDictionary objectForKey:@"error"] forKey:NSLocalizedDescriptionKey]];
    }
    
    self.done = YES;
}

@end

@implementation SMXTwitterWebViewController

@synthesize twitterDelegate;

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return [self.twitterDelegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
}

- (BOOL) shouldPresentActionSheet:(UIActionSheet *)actionSheet
{
    return NO;
}

@end