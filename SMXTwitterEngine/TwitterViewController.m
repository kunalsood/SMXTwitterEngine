//
//  TwitterViewController.m
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 The Lab, Telefonica UK Ltd. All rights reserved.
//

#import "TwitterViewController.h"
#import "SMXTwitterEngine.h"

@implementation TwitterViewController
@synthesize tweetField;
@synthesize tweetButton;

- (void) viewDidAppear:(BOOL)animated
{
    //[self.tweetField becomeFirstResponder];
	[SMXTwitterEngine streamTweetsWithHandler:^(NSDictionary *object, NSError *error) {
		NSLog(@"%@", object);
	}];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self sendTweet:textField];
    return YES;
}

- (IBAction)sendTweet:(id)sender {
    self.tweetButton.enabled = NO;
    [SMXTwitterEngine setConsumerKey:@"z0UAUAiauMKylCJYsKePg" consumerSecret:@"OZAGlveHaIb5FqiC2hec7Fps2Hf7ZRDsu5Olb70anw" callback:@"http://simonmaddox.com"];
    
    [SMXTwitterEngine setUseTweetComposeSheetIfPossible:YES];
    
    [SMXTwitterEngine sendTweet:self.tweetField.text andImage:[UIImage imageNamed:@"apple"] withCompletionHandler:^(NSDictionary *response, NSError *error){
        self.tweetButton.enabled = YES;
        if (error){
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
            [alert show];
        } else {
            UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Tweet Posted" message:nil delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
            [alert show];
        }
    }];
}

- (void)dealloc {
    [tweetField release];
    [tweetButton release];
    [super dealloc];
}
- (void)viewDidUnload {
    [self setTweetField:nil];
    [self setTweetButton:nil];
    [super viewDidUnload];
}
@end
