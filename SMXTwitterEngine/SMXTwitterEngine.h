//
//  SMXTwitterEngine.h
//  SMXTwitterEngine
//
//  Created by Simon Maddox on 09/05/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SMXTwitterEngine : NSObject

+ (void) sendTweet:(NSString *)tweet withCompletionHandler:(void (^)(id response, NSError *error))handler;

@end
