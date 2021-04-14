//
//  XYQMovieViewController.h
//  Iat
//
//  Created by Junco on 17/5/17.
//  Copyright © 2017年 Friends-Tech. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol XYQMovieViewControllerDelegate <NSObject>

- (void)endPlayVideo;

@end

@interface XYQMovieViewController : UIViewController
@property(nonatomic, assign) id<XYQMovieViewControllerDelegate> delegate;
@property(nonatomic, copy) NSString *playUrl;
- (void)initWithVideos:(NSMutableArray *)vedios;

@end
