//
//  WebViewController.m
//  CallingCards
//
//  Created by Simon Maddox on 26/04/2011.
//  Copyright 2011 Telefonica UK Ltd. All rights reserved.
//

#import "WebViewController.h"
#import "UIImage+Retina.h"

@implementation WebViewController
@synthesize webView;
@synthesize webViewControllerDelegate;
@synthesize backButton, forwardButton, actionButton, fixedSpace, url, html;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
	self.html = nil;
    [webView release];
	self.url = nil;
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	connections = 0;
	
	self.navigationController.toolbarHidden = NO;
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Close" style:UIBarButtonItemStyleBordered target:self action:@selector(close)] autorelease];
	
	self.backButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfResolutionIndependentFile:[[NSBundle mainBundle] pathForResource:@"back" ofType:@"png"]] style:UIBarButtonItemStylePlain target:self action:@selector(goBack)] autorelease];
	self.forwardButton = [[[UIBarButtonItem alloc] initWithImage:[UIImage imageWithContentsOfResolutionIndependentFile:[[NSBundle mainBundle] pathForResource:@"forw" ofType:@"png"]] style:UIBarButtonItemStylePlain target:self action:@selector(goForward)] autorelease];
	self.actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed)] autorelease];
	
	self.fixedSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil] autorelease];

	[self setToolbarItems:[NSArray arrayWithObjects:self.backButton, self.fixedSpace, self.forwardButton, [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease], self.actionButton, nil]];
	
	self.fixedSpace.width = 15;
	
	self.backButton.enabled = NO;
	self.forwardButton.enabled = NO;
	self.actionButton.enabled = NO;
	
	if (self.url != nil){
		[self.webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	} else if (self.html != nil){
		[self.webView loadHTMLString:self.html baseURL:nil];
	}
}

- (void)viewDidUnload
{
    [self setWebView:nil];
	self.backButton = nil;
	self.forwardButton = nil;
	self.actionButton = nil;
	self.fixedSpace = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return YES; //(interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	connections++;
	[self checkSpinner];
	
	self.title = @"";
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	connections--;
	[self checkSpinner];
	
	if (connections == 0){
		self.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
	}
	
	if ([self.webView canGoBack]){
		self.backButton.enabled = YES;
	} else {
		self.backButton.enabled = NO;
	}
	
	if ([self.webView canGoForward]){
		self.forwardButton.enabled = YES;
	} else {
		self.forwardButton.enabled = NO;
	}
	
	if (!self.actionButton.enabled && connections == 0){
		self.actionButton.enabled = YES;
	}
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	connections--;
	[self checkSpinner];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([self.webViewControllerDelegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]){
        return [self.webViewControllerDelegate webView:aWebView shouldStartLoadWithRequest:request navigationType:navigationType];
    } else {
        return YES;
    }
}

- (void) checkSpinner
{
	if (connections > 0 && ![[UIApplication sharedApplication] isNetworkActivityIndicatorVisible]){
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	} else if (connections == 0 && [[UIApplication sharedApplication] isNetworkActivityIndicatorVisible]){
		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
}

- (void) close
{
	[self setWebView:nil];
	connections = 0;
	[self checkSpinner];
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void) goBack
{
	[self.webView goBack];
}

- (void) goForward
{
	[self.webView goForward];
}

- (void) actionButtonPressed
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:[[[self.webView request] URL] absoluteString] delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"Open in Safari", nil];
	[actionSheet showFromToolbar:self.navigationController.toolbar];
	[actionSheet release];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (actionSheet.firstOtherButtonIndex == buttonIndex){
		[[UIApplication sharedApplication] openURL:[[self.webView request] URL]];
	}
}

@end
