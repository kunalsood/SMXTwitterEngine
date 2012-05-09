//
//  WebViewController.h
//  CallingCards
//
//  Created by Simon Maddox on 26/04/2011.
//  Copyright 2011 Telefonica UK Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WebViewControllerDelegate <NSObject>

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;

@end


@interface WebViewController : UIViewController <UIWebViewDelegate, UIActionSheetDelegate> {
	UIWebView *webView;
	NSInteger connections;
}

@property (nonatomic, retain) IBOutlet UIWebView *webView;
@property (nonatomic, retain) NSURL *url;
@property (nonatomic, retain) NSString *html;

@property (nonatomic, retain) UIBarButtonItem *backButton;
@property (nonatomic, retain) UIBarButtonItem *forwardButton;
@property (nonatomic, retain) UIBarButtonItem *actionButton;
@property (nonatomic, retain) UIBarButtonItem *fixedSpace;
@property (nonatomic, assign) id <WebViewControllerDelegate> webViewControllerDelegate;

- (void) checkSpinner;

@end
