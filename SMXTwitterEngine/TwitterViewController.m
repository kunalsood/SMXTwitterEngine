//
//  TwitterViewController.m
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TwitterViewController.h"
#import "SMXTwitterEngine.h"

@implementation TwitterViewController

- (IBAction)sendTweet:(id)sender {
    [SMXTwitterEngine setConsumerKey:@"z0UAUAiauMKylCJYsKePg" consumerSecret:@"OZAGlveHaIb5FqiC2hec7Fps2Hf7ZRDsu5Olb70anw" callback:@"http://simonmaddox.com"];
    
    [SMXTwitterEngine sendTweet:@"Hello Twitter (this is a test)" withCompletionHandler:^(NSDictionary *response, NSError *error){
        NSLog(@"Response: %@", response); 
        NSLog(@"Error: %@", error);
    }];
}

@end
