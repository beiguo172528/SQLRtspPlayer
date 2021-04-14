//
//  ViewController.m
//  SQLRtspPlayer
//
//  Created by DOFAR on 2021/4/14.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "XYQMovieViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (IBAction)toPlayRtsp:(id)sender {
    XYQMovieViewController *vc = [[XYQMovieViewController alloc]init];
    vc.playUrl = @"rtsp://wowzaec2demo.streamlock.net/vod/mp4:BigBuckBunny_115k.mov";
    vc.modalPresentationStyle = UIModalPresentationFullScreen;
    AppDelegate *app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    app.isForcePortrait=NO;
    app.isForceLandscape=YES;
    [self presentViewController:vc animated:YES completion:nil];
}

@end
