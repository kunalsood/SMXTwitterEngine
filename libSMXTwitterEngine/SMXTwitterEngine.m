//
//  SMXTwitterEngine.m
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 The Lab, Telefonica UK Ltd. All rights reserved.
//

#import "SMXTwitterEngine.h"
#import <Twitter/Twitter.h>
#import <Accounts/Accounts.h>
#import "UIAlertView+MKBlockAdditions.h"

#import "OADataFetcher.h"
#import "OAToken.h"

#import "THWebController.h"

#import "Tweet.h"

#import "SMXURLConnection.h"

typedef void(^TwitterWebViewAuthorizedHandler)(NSDictionary *parameters);

@interface SMXTwitterEngine () {
}

+ (void) useAccount:(ACAccount *)account toSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler;

@end

@interface SMXTwitterWebViewController : THWebController
@property (nonatomic, copy) TwitterWebViewAuthorizedHandler authorizedHandler;
@end

@implementation SMXTwitterEngine

#pragma mark - Post Tweet

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler;
{
	[SMXTwitterEngine sendTweet:tweet andImage:nil withCompletionHandler:handler];
}

+ (void) sendTweet:(NSString *)tweet andImage:(UIImage *)image withCompletionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    Tweet *t = [[[Tweet alloc] init] autorelease];
    t.tweet = tweet;
    t.image = image;
        
	BOOL useComposeSheet = [[NSUserDefaults standardUserDefaults] boolForKey:@"SMXTwitterEngineUseTweetComposeSheet"];
	if (!useComposeSheet){
		[SMXTwitterEngine chooseAccountWithCompletionHandler:^(ACAccount *account, NSError *error) {
			if (account != nil){
				[SMXTwitterEngine useAccount:account
								 toSendTweet:t
						   completionHandler:^(NSDictionary *response, NSError *error) {
							  handler(response, error);
						  }];
			} else if (account == nil && error == nil){ // use manual OAuth
				[SMXTwitterEngine fetchAccessTokenWithCompletionHandler:^(OAToken *accessToken, NSError *error) {
					[SMXTwitterEngine postTweet:t usingAccessToken:accessToken completionHandler:^(NSDictionary *response, NSError *error) {
						dispatch_async(dispatch_get_main_queue(), ^(){
							handler(response, error);
						});
					}];
				}];
			} else {
				dispatch_async(dispatch_get_main_queue(), ^(){
					handler(nil, error);
				});
			}
		}];
	} else {
		[SMXTwitterEngine postTweetusingComposeSheet:t
								   completionHandler:^(NSDictionary *response, NSError *error) {
									   dispatch_async(dispatch_get_main_queue(), ^(){
										   handler(response, error);
									   });
								   }];
	}
}

#pragma mark Twitter.framework

+ (void) chooseAccountWithCompletionHandler:(void (^)(ACAccount *account, NSError *error))handler
{
	ACAccountStore *accountStore = [[ACAccountStore alloc] init];
	
	[accountStore requestAccessToAccountsWithType:[accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]
							withCompletionHandler:^(BOOL granted, NSError *error){
								if (granted){
									NSArray *accounts = [accountStore accountsWithAccountType:[accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]];
									
									if (accounts.count == 0){
										// No accounts set up. Let's fall back to OAuth
										handler(nil, nil);
									} else {
										
										if (accounts.count == 1){
											// One account set up. Let's use that.
											handler([accounts objectAtIndex:0], nil);
										} else {
											// More than one account set up. Let's ask which one we should use...
											NSArray *accountTitles = [accounts valueForKeyPath:@"accountDescription"];
											NSMutableArray *titles = [NSMutableArray arrayWithArray:accountTitles];
											if ([[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineConsumerKey"] != nil){
												[titles addObject:NSLocalizedString(@"Another Account", @"Another Account alert title")];
											}
											
											dispatch_async(dispatch_get_main_queue(), ^(){
												[UIAlertView alertViewWithTitle:NSLocalizedString(@"Choose a Twitter account", @"Choose a Twitter account alert title")
																		message:nil
															  cancelButtonTitle:NSLocalizedString(@"Cancel", @"Choose a Twitter account alert cancel button")
															  otherButtonTitles:titles
																	  onDismiss:^(int buttonIndex){
																		  if ([[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineConsumerKey"] != nil && buttonIndex == (titles.count - 1)){
																			  handler(nil, nil);
																		  } else {
																			  handler([accounts objectAtIndex:buttonIndex], nil);
																		  }
																	  }
																	   onCancel:^(){
																			handler(nil, [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:101 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User Cancelled", @"User Cancelled error message") forKey:NSLocalizedDescriptionKey]]);
																	   }
												 ];
												
											});
										}
										
									}
								} else {
									handler(nil, [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:403 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User did not allow access to Twitter accounts", @"User did not allow access to Twitter accounts error message") forKey:NSLocalizedDescriptionKey]]);
								}
							}
	 ];

	
}

+ (void) postTweetusingComposeSheet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
	dispatch_async(dispatch_get_main_queue(), ^(){
		TWTweetComposeViewController *tweetComposeViewController = [[[TWTweetComposeViewController alloc] init] autorelease];
		[tweetComposeViewController setInitialText:tweet.tweet];
		[tweetComposeViewController addImage:tweet.image];
		[tweetComposeViewController setCompletionHandler:^(TWTweetComposeViewControllerResult result){
			dispatch_async(dispatch_get_main_queue(), ^(){
				NSError *error = nil;
				if (result == TWTweetComposeViewControllerResultCancelled){
					error = [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:101 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User Cancelled", @"User Cancelled error message") forKey:NSLocalizedDescriptionKey]];
				}
				
				handler([NSDictionary dictionary], error);
			});
		}];
		UIViewController *baseViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
		while ([baseViewController modalViewController]) {
			baseViewController = [baseViewController modalViewController];
		}
		[baseViewController presentModalViewController:tweetComposeViewController animated:YES];
	});
}

+ (void) useAccount:(ACAccount *)account toSendTweet:(Tweet *)tweet completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
    TWRequest *twitterRequest = nil;
    
    if (tweet.image == nil){
        twitterRequest = [[[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"]
                                                    parameters:[NSDictionary dictionaryWithObject:tweet.tweet forKey:@"status"] 
                                                 requestMethod:TWRequestMethodPOST] autorelease];
    } else {
        twitterRequest = [[[TWRequest alloc] initWithURL:[NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"] 
                                              parameters:nil 
                                           requestMethod:TWRequestMethodPOST] autorelease];
        [twitterRequest addMultiPartData:UIImagePNGRepresentation(tweet.image) withName:@"media" type:@"image/png"];
        [twitterRequest addMultiPartData:[tweet.tweet dataUsingEncoding:NSUTF8StringEncoding] withName:@"status" type:@"text/plain"];
    }
    
    [twitterRequest setAccount:account];
    
    [twitterRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error){
        NSError *jsonError = nil;
        NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&jsonError];
        
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

#pragma mark OAuth

+ (OAConsumer *) oAuthConsumer
{
	NSString *key = [[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineConsumerKey"];
	NSString *secret = [[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineConsumerSecret"];
	
	return [[[OAConsumer alloc] initWithKey:key secret:secret] autorelease];
}

+ (void) fetchAccessTokenWithCompletionHandler:(void (^)(OAToken *accessToken, NSError *error))handler
{
	OAToken *token = [[[OAToken alloc] initWithUserDefaultsUsingServiceProviderName:@"SMXTwitterEngineAccessToken" prefix:nil] autorelease];
	if (token.isValid){
		handler(token, nil);
	} else {
	
		NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/request_token"];
		
		__block OAConsumer *consumer = [SMXTwitterEngine oAuthConsumer];
		
		OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																		consumer:consumer
																		   token:nil
																		   realm:nil
															   signatureProvider:nil];
		
		[request setHTTPMethod:@"POST"];
		[request prepare];
		
		[NSURLConnection sendAsynchronousRequest:request
										   queue:[NSOperationQueue mainQueue]
							   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
								   NSString *responseBody = [[[NSString alloc] initWithData:data
																				   encoding:NSUTF8StringEncoding] autorelease];
								   
								   __block OAToken *token = [[OAToken alloc] initWithHTTPResponseBody:responseBody];
								   
								   NSString *address = [NSString stringWithFormat:
														@"https://api.twitter.com/oauth/authorize?oauth_token=%@",
														token.key];
								   
								   NSURL *url = [NSURL URLWithString:address];
								   
								   dispatch_async(dispatch_get_main_queue(), ^(){
									   
									   UIViewController *presentationViewController = [[[UIApplication sharedApplication] keyWindow] rootViewController];
									   while ([presentationViewController modalViewController]) {
										   presentationViewController = [presentationViewController modalViewController];
									   }
									   
									   SMXTwitterWebViewController *webViewController = [[SMXTwitterWebViewController alloc] init];
									   [webViewController setAuthorizedHandler:^(NSDictionary *parameters){
										   [token setVerifier:[parameters objectForKey:@"oauth_verifier"]];
										   
										   
										   NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/oauth/access_token"];
										   
										   OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
																										   consumer:consumer
																											  token:token
																											  realm:nil
																								  signatureProvider:nil] autorelease];
										   
										   [request setHTTPMethod:@"POST"];
										   [request prepare];
										   
										   
										   
										   [NSURLConnection sendAsynchronousRequest:request
																			  queue:[NSOperationQueue mainQueue]
																  completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
																	  NSString *responseBody = [[[NSString alloc] initWithData:data
																													  encoding:NSUTF8StringEncoding] autorelease];
																	  
																	  OAToken *accessToken = [[[OAToken alloc] initWithHTTPResponseBody:responseBody] autorelease];
																	  [accessToken storeInUserDefaultsWithServiceProviderName:@"SMXTwitterEngineAccessToken" prefix:nil];
																	  handler(accessToken, nil);
																  }];
										   
										   
									   }];
									   [webViewController openURL:url];
									   UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webViewController];
									   [presentationViewController presentModalViewController:navigationController animated:YES];
									   [webViewController release];
									   [navigationController release];
								   });
								   
							   }];
	}
}

+ (void) postTweet:(Tweet *)tweet usingAccessToken:(OAToken *)accessToken completionHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
	NSURL *url = nil;
    
    if (tweet.image == nil){
        url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.twitter.com/1/statuses/update.json"]];
    } else {
        url = [NSURL URLWithString:@"https://upload.twitter.com/1/statuses/update_with_media.json"];
    }
    
    OAMutableURLRequest *request = [[[OAMutableURLRequest alloc] initWithURL:url
																	consumer:[SMXTwitterEngine oAuthConsumer]
																	   token:accessToken
																	   realm:nil
														   signatureProvider:nil] autorelease];
    
    [request setHTTPMethod:@"POST"];
    
    if (tweet.image == nil){
        [request setHTTPBody:[[NSString stringWithFormat:@"status=%@", [tweet.tweet encodedURLParameterString]] dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        // From http://stackoverflow.com/a/7343889/891910
        
        NSString *boundary = @"----------------------------991990ee82f7";
        
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
        [request setValue:contentType forHTTPHeaderField:@"content-type"];
        
        NSMutableData *body = [NSMutableData dataWithLength:0];
        [body appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Disposition: form-data; name=\"media[]\"; filename=\"media.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Type: application/octet-stream\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:UIImagePNGRepresentation(tweet.image)];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"status\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithString:[NSString stringWithFormat:@"%@\r\n", tweet.tweet]] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"--%@--\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		
        [request setHTTPBody:body];
    }
	
	[request prepare];
	
	[NSURLConnection sendAsynchronousRequest:request
									   queue:[NSOperationQueue mainQueue]
						   completionHandler:^(NSURLResponse *response, NSData *data, NSError *error){
							   handler([NSJSONSerialization JSONObjectWithData:data options:0 error:nil], error);
						   }];
}

+ (void) setConsumerKey:(NSString *)consumerKey consumerSecret:(NSString *)consumerSecret callback:(NSString *)callback
{
    [[NSUserDefaults standardUserDefaults] setObject:consumerKey forKey:@"SMXTwitterEngineConsumerKey"];
    [[NSUserDefaults standardUserDefaults] setObject:consumerSecret forKey:@"SMXTwitterEngineConsumerSecret"];
    [[NSUserDefaults standardUserDefaults] setObject:callback forKey:@"SMXTwitterEngineCallback"];
}

+ (void) setUseTweetComposeSheetIfPossible:(BOOL)useTweetComposeSheet
{
    [[NSUserDefaults standardUserDefaults] setBool:useTweetComposeSheet forKey:@"SMXTwitterEngineUseTweetComposeSheet"];
}

#pragma mark - Stream Tweets

+ (void) streamTweetsWithHandler:(void (^)(NSDictionary *response, NSError *error))handler
{
	
	[SMXTwitterEngine chooseAccountWithCompletionHandler:^(ACAccount *account, NSError *error) {
		if (account != nil){
			// TODO: Use TWRequest for streaming
		} else if (account == nil && error == nil){ // use manual OAuth
			[SMXTwitterEngine fetchAccessTokenWithCompletionHandler:^(OAToken *accessToken, NSError *error) {
				NSURL *url = [NSURL URLWithString:@"https://stream.twitter.com/1/statuses/sample.json"];
				OAMutableURLRequest *request = [[OAMutableURLRequest alloc] initWithURL:url
																			   consumer:[SMXTwitterEngine oAuthConsumer]
																				  token:accessToken
																				  realm:nil
																	  signatureProvider:nil];
				[request prepare];
				
				
				SMXURLConnection *connection = [[SMXURLConnection alloc] initWithRequest:request delegate:nil];
				[connection setDataHandler:^(NSData *data) {
					NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
					if (dictionary != nil){
						handler(dictionary, nil);
					}
				}];
				[connection setCompletionHandler:^(NSError *error) {
					NSLog(@"Done streaming");
				}];
				[connection start];
				
			}];
		} else {
			dispatch_async(dispatch_get_main_queue(), ^(){
				handler(nil, error);
			});
		}
	}];
}

@end



@implementation SMXTwitterWebViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStyleBordered target:self action:@selector(cancel)] autorelease];
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if ([[[request URL] absoluteString] rangeOfString:[[NSUserDefaults standardUserDefaults] stringForKey:@"SMXTwitterEngineCallback"]].length > 0){
		
		NSMutableDictionary *parameters = [NSMutableDictionary dictionary];
		
        NSArray *urlPieces = [[[request URL] absoluteString] componentsSeparatedByString:@"?"];
        
        NSArray *params = [[urlPieces objectAtIndex:1] componentsSeparatedByString:@"&"];
        
        for (NSString *p in params){
            NSArray *pieces = [p componentsSeparatedByString:@"="];
            [parameters setObject:[pieces objectAtIndex:1] forKey:[pieces objectAtIndex:0]];
        }
		
		if (self.authorizedHandler != nil){
			self.authorizedHandler(parameters);
			[self.navigationController dismissModalViewControllerAnimated:YES];
		}
		return NO;
	} else {
		return YES;
	}
}

- (BOOL) shouldPresentActionSheet:(UIActionSheet *)actionSheet
{
    return NO;
}

- (void) cancel
{
    /*((SMXTwitterEngineHandler *)self.twitterDelegate).error = [NSError errorWithDomain:@"com.simonmaddox.ios.SMXTwitterEngine" code:101 userInfo:[NSDictionary dictionaryWithObject:NSLocalizedString(@"User Cancelled", @"User Cancelled error message") forKey:NSLocalizedDescriptionKey]];
    ((SMXTwitterEngineHandler *)self.twitterDelegate).done = YES;
    
    [self.navigationController dismissModalViewControllerAnimated:YES];*/
    
}

@end