//
//  SMXURLConnection.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 29/08/2012.
//
//

#import <Foundation/Foundation.h>

typedef void (^DataReceivedBlock)(NSData *data);
typedef void (^ConnectionCompletedBlock)(NSError *error);

@interface SMXURLConnection : NSURLConnection

- (id) initWithRequest:(NSURLRequest *)request delegate:(id)delegate;

@property (nonatomic, copy) DataReceivedBlock dataHandler;
@property (nonatomic, copy) ConnectionCompletedBlock completionHandler;

- (void) setDataHandler:(DataReceivedBlock)dataHandler;
- (void) setCompletionHandler:(ConnectionCompletedBlock)completionHandler;

@end
