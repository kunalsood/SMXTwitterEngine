//
//  TwitterViewController.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 The Lab, Telefonica UK Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TwitterViewController : UIViewController <UITextFieldDelegate>

- (IBAction)sendTweet:(id)sender;
@property (strong, nonatomic) IBOutlet UITextField *tweetField;
@property (strong, nonatomic) IBOutlet UIButton *tweetButton;

@end
