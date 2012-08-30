//
//  SMXURLConnection.m
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 29/08/2012.
//
//

#import "SMXURLConnection.h"

@interface SMXURLConnection () <NSURLConnectionDataDelegate, NSURLConnectionDelegate>

@property (nonatomic, weak) id <NSURLConnectionDataDelegate> realDelegate;

@end

@implementation SMXURLConnection

@synthesize dataHandler, completionHandler;

- (id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate
{
	if (self = [super initWithRequest:request delegate:self]){
		self.realDelegate = delegate;
	}
	
	return self;
}

#pragma mark - NSURLConnectionDataDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
	if ([self.realDelegate respondsToSelector:@selector(connection:willSendRequest:redirectResponse:)]){
		return [self.realDelegate connection:connection willSendRequest:request redirectResponse:response];
	}
	
	return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if ([self.realDelegate respondsToSelector:@selector(connection:didReceiveResponse:)]){
		[self.realDelegate connection:connection didReceiveResponse:response];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if (self.dataHandler != nil){
		self.dataHandler(data);
	}
	
	// For some reason, the delegate might be listening to both of these. I've no idea why, but...just in case.
	if ([self.realDelegate respondsToSelector:@selector(connection:didReceiveData:)]){
		[self.realDelegate connection:connection didReceiveData:data];
	}
}

- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request
{
	if ([self.realDelegate respondsToSelector:@selector(connection:needNewBodyStream:)]){
		return [self.realDelegate connection:connection needNewBodyStream:request];
	}
	return nil;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	if ([self.realDelegate respondsToSelector:@selector(connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite:)]){
		[self.realDelegate connection:connection didSendBodyData:bytesWritten totalBytesWritten:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
	}
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
	if ([self.realDelegate respondsToSelector:@selector(connection:willCacheResponse:)]){
		return [self.realDelegate connection:connection willCacheResponse:cachedResponse];
	}
	return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	if (self.completionHandler != nil){
		self.completionHandler(nil);
	}
	
	if ([self.realDelegate respondsToSelector:@selector(connectionDidFinishLoading:)]){
		[self.realDelegate connectionDidFinishLoading:connection];
	}
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	if (self.completionHandler != nil){
		self.completionHandler(error);
	}
	
	if ([self.realDelegate respondsToSelector:@selector(connection:didFailWithError:)]){
		[self.realDelegate connection:connection didFailWithError:error];
	}
}

- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection
{
	if ([self.realDelegate respondsToSelector:@selector(connectionShouldUseCredentialStorage:)]){
		return [self.realDelegate connectionShouldUseCredentialStorage:connection];
	}
	
	return YES;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
	if ([self.realDelegate respondsToSelector:@selector(connection:willSendRequestForAuthenticationChallenge:)]){
		[self.realDelegate connection:connection willSendRequestForAuthenticationChallenge:challenge];
	} else {
		NSURLCredential *credential = [NSURLCredential credentialWithUser:[[[connection currentRequest] URL] user]
																 password:[[[connection currentRequest] URL] password]
															  persistence:NSURLCredentialPersistenceForSession];
		[[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
	}
}

@end
