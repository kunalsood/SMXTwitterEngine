//
//  UIImage+Retina.h
//  CallingCards
//
//  Created by Simon Maddox on 28/04/2011.
//  Copyright 2011 Telefonica UK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface UIImage (UIImage_Retina)

- (id)initWithContentsOfResolutionIndependentFile:(NSString *)path;
+ (UIImage*)imageWithContentsOfResolutionIndependentFile:(NSString *)path;

@end
