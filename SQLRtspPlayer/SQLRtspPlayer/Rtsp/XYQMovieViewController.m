//
//  XYQMovieViewController.m
//  Iat
//
//  Created by Junco on 17/5/17.
//  Copyright © 2017年 Friends-Tech. All rights reserved.
//

#import "XYQMovieViewController.h"
#import <MobileVLCKit/MobileVLCKit.h>
//#import "Masonry.h"

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

#define MaxScale 3.0  //最大缩放比例
#define MinScale 1.0  //最小缩放比例

@interface XYQMovieViewController () {
    UITapGestureRecognizer *tapGestureRecognizer;
    UITapGestureRecognizer *doubleTapGestureRecognizer;
    UIPanGestureRecognizer *panGestureRecognizer;
    UIActivityIndicatorView *activityIndicatorView;
    
    dispatch_queue_t  dispatchQueue;
    BOOL      _hiddenHUD;
    UIView    *topHUD;
    UIButton  *exitButton;
    
    NSMutableArray *switchButtons;
    UIButton  *frame_x1;
    UIButton  *frame_x2;
    UIButton  *frame_x3;
    
    UIButton     *pause;
    UIBarButtonItem     *playBtn;
    UIBarButtonItem     *pauseBtn;
    BOOL      playing;
    
    CGFloat   lastScale;
    CGPoint   lastPoint;
    CGPoint   centerPoint;
    CGRect    _oldImageViewFrame;
    
    NSUInteger selIdx;
    NSUInteger maxIdx;
    
    CGFloat mixScale, maxScale;
}
@property (strong, nonatomic) NSTimer *nextFrameTimer;
@property (strong, nonatomic) UIImageView *ImageView;
@property (strong, nonatomic) UIView *movieView;
@property (strong, nonatomic) VLCMedia *media;
@property (strong, nonatomic) VLCMediaPlayer *mediaPlayer;
@property (strong, nonatomic) NSMutableArray *videosArray;
@property (assign, nonatomic) CGFloat totalScale;

@end

@implementation XYQMovieViewController

- (void)initWithVideos:(NSMutableArray *)vedios {
    _videosArray = vedios;
    maxIdx = _videosArray.count;
}

- (UIView *)movieView {
    if (!_movieView) {
        UIView *v = [[UIView alloc] initWithFrame:self.view.bounds];
        [self.view addSubview:v];
        v.backgroundColor = [UIColor whiteColor];
    }
    return _movieView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
//    [WJStatusBarHUD hide];
    _totalScale = 1.0;
    [self.view bringSubviewToFront:activityIndicatorView];
    [activityIndicatorView startAnimating];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(invalidNetwork) name:@"Notification_invalidNetWork" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(validNetwork) name:@"Notification_NetWifiRecovered" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(popViewController) name:@"Disconnect_Rtsp" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(popViewController) name:@"ExitFullScreen" object:nil];
    
}

- (void)viewDidAppear:(BOOL)animated {
    _hiddenHUD = YES;
    [self performSelector:@selector(hiddenHUD) withObject:nil afterDelay:4.0];
    
    selIdx = 0;
    
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(checkIsPalying) userInfo:nil repeats:YES];
    _nextFrameTimer = timer;

    NSString *urlPath = [self getUrlPath];
    if (urlPath.length == 0) {
//        [WJStatusBarHUD showErrorImageName:@"" text:@"未获取到直播地址"];
        return;
    }
    
    VLCMediaPlayer *player = [[VLCMediaPlayer alloc] initWithOptions:nil];
    self.mediaPlayer = player;
    self.mediaPlayer.drawable = _movieView;
    self.mediaPlayer.media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlPath]];
    [self.mediaPlayer play];
    playing = YES;
    
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.mediaPlayer stop];
    [_nextFrameTimer invalidate];
    _nextFrameTimer = nil;
    
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)popViewController {
    if(self.delegate && [self.delegate respondsToSelector:@selector(endPlayVideo)]){
        [self.delegate endPlayVideo];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
//    [WJStatusBarHUD showImageName:@"" text:@"直播已关闭"];
}

- (void)checkIsPalying {
    if (self.mediaPlayer.isPlaying) {
        if (activityIndicatorView.animating) {
            [activityIndicatorView stopAnimating];
        }
    } else {
        if (!activityIndicatorView.animating) {
            [activityIndicatorView startAnimating];
        }
    }
}

- (void)loadView {
    CGRect bounds = [[UIScreen mainScreen] bounds];
    
    self.view = [[UIView alloc] initWithFrame:bounds];
    self.view.backgroundColor = [UIColor blackColor];
    self.view.tintColor = [UIColor blackColor];

    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height;
    
    CGFloat topH = 50;
    
    topHUD    = [[UIView alloc] initWithFrame:CGRectMake(0,0,0,0)];
    topHUD.backgroundColor = [UIColor lightGrayColor];
    
    topHUD.frame = CGRectMake(0,0,width,topH);
    topHUD.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    [self.view addSubview:topHUD];
    
    UIImage *image = [UIImage imageNamed:@"back"];
    
    exitButton = [UIButton buttonWithType:UIButtonTypeCustom];
    exitButton.frame = CGRectMake(0, 1, 100, topH);
    exitButton.backgroundColor = [UIColor clearColor];
    [exitButton setImage:image forState:UIControlStateNormal];
    [exitButton setTitle:@"退出" forState:UIControlStateNormal];
    exitButton.imageEdgeInsets = UIEdgeInsetsMake(14,10,14,20);
    exitButton.showsTouchWhenHighlighted = YES;
    [exitButton addTarget:self action:@selector(exitDidTouch)
          forControlEvents:UIControlEventTouchUpInside];
    
//    if (_videosArray.count > 0) {
//        switchButtons = [[NSMutableArray alloc]init];
//        for (int i = 0; i < _videosArray.count; i ++) {
//            NSMutableDictionary *dict = [_videosArray objectAtIndex:i];
//            NSString *btnTitle = [dict objectForKey:@"name"];
//            UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(headX, 1, 50, topH)];
//            [btn setTitle:btnTitle forState:UIControlStateNormal];
//            [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//            [btn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateSelected];
//            [btn addTarget:self action:@selector(switchVideo:) forControlEvents:UIControlEventTouchUpInside];
//            btn.tag = i;
//            [topHUD addSubview:btn];
//            [switchButtons addObject:btn];
//            headX += 50;
//            if (i == 0) {
//                btn.selected = YES;
//                btn.userInteractionEnabled = NO;
//            }
//        }
//    }
//    headX += 10;
//    frame_x1 = [[UIButton alloc]initWithFrame:CGRectMake(headX , 10, 30, 30)];
//    [frame_x1 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
//    [frame_x1 setTitle:@"x1" forState:UIControlStateNormal];
//    [frame_x1 addTarget:self action:@selector(ScaleToOriginal) forControlEvents:UIControlEventTouchUpInside];
//    
//    frame_x2 = [[UIButton alloc]initWithFrame:CGRectMake(headX + 40, 10, 30, 30)];
//    [frame_x2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [frame_x2 setTitle:@"x2" forState:UIControlStateNormal];
//    [frame_x2 addTarget:self action:@selector(ScaleToDouble) forControlEvents:UIControlEventTouchUpInside];
//    
//    frame_x3 = [[UIButton alloc]initWithFrame:CGRectMake(headX + 80, 10, 30, 30)];
//    [frame_x3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
//    [frame_x3 setTitle:@"x3" forState:UIControlStateNormal];
//    [frame_x3 addTarget:self action:@selector(ScaleToTriple) forControlEvents:UIControlEventTouchUpInside];
    
//    pause = [[UIButton alloc]initWithFrame:CGRectMake(headX, 1, 50, topH)];//115
//    pause.titleLabel.font = [UIFont systemFontOfSize:18];
//    [pause setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [pause setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateNormal];
//    [pause setImage:[UIImage imageNamed:@"play"] forState:UIControlStateSelected];
//    pause.imageEdgeInsets = UIEdgeInsetsMake(9,13,9,13);
//    [pause addTarget:self action:@selector(pauseDidTouch) forControlEvents:UIControlEventTouchUpInside];

    [topHUD addSubview:exitButton];
//    [topHUD addSubview:frame_x1];
//    [topHUD addSubview:frame_x2];
//    [topHUD addSubview:frame_x3];
//    [topHUD addSubview:pause];
    
//    _ImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, height + 20, width)];
//    _oldImageViewFrame = _ImageView.frame;
    _movieView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, height + 20, width)];
    _oldImageViewFrame = _movieView.frame;
    
    [self.view addSubview:_movieView];
    [self.view bringSubviewToFront:topHUD];
    
    activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhiteLarge];
    activityIndicatorView.center = self.view.center;
    activityIndicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [self.view addSubview:activityIndicatorView];
    
    [self setupUserInteraction];
}

- (void) setupUserInteraction
{
    self.view.userInteractionEnabled = YES;
    _movieView.userInteractionEnabled = YES;
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapGestureRecognizer.numberOfTapsRequired = 1;
    
    doubleTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    doubleTapGestureRecognizer.numberOfTapsRequired = 2;
    
    [tapGestureRecognizer requireGestureRecognizerToFail: doubleTapGestureRecognizer];
    
    //拖动
    UIPanGestureRecognizer *panGR=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panImageView:)];
    [_movieView addGestureRecognizer:panGR];
    
    //两个手指放大缩小
    UIPinchGestureRecognizer *pinchRecognizer =  [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(handlePinch:)];
    [_movieView addGestureRecognizer:doubleTapGestureRecognizer];
    [_movieView addGestureRecognizer:tapGestureRecognizer];
    [_movieView addGestureRecognizer:pinchRecognizer];
}

#pragma mark - network change

- (void)invalidNetwork {
    //关闭定时器
    [_nextFrameTimer setFireDate:[NSDate distantFuture]];
    [activityIndicatorView startAnimating];
}

- (void)validNetwork {
    //开启定时器
    [_nextFrameTimer setFireDate:[NSDate distantPast]];
    [activityIndicatorView stopAnimating];
}


#pragma mark - gesture recognizer

- (void) hiddenHUD {
    _hiddenHUD = YES;
    [self showHUD:NO];
}

- (void) showHUD: (BOOL) show
{
    _hiddenHUD = !show;
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:_hiddenHUD];
    
    [UIView animateWithDuration:0.2
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut | UIViewAnimationOptionTransitionNone
                     animations:^{
                         
        CGFloat alpha = self->_hiddenHUD ? 0 : 1;
        self->topHUD.alpha = alpha;
                     }
                     completion:nil];
}

- (void)exitDidTouch {
    NSLog(@"exitDidTouch");
    if (self.presentingViewController || !self.navigationController)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)updateSwitchButtons {
    for (UIButton *button in switchButtons) {
        button.selected = NO;
        button.userInteractionEnabled = YES;
    }
}

- (void)switchVideo: (UIButton *)button {
    if (button.tag != selIdx) {
        [_nextFrameTimer invalidate];
        [self updateSwitchButtons];
        selIdx = button.tag;
        button.selected = YES;
        button.userInteractionEnabled = NO;
        [self initVideo];
    }
}

- (VLCMediaPlayer *)mediaPlayer {
    if (!_mediaPlayer) {
        _mediaPlayer = [[VLCMediaPlayer alloc] init];
    }
    return _mediaPlayer;
}

- (void)initVideo {
    NSString *urlPath = [self getUrlPath];
    self.mediaPlayer.media = [VLCMedia mediaWithURL:[NSURL URLWithString:urlPath]];
    [self.mediaPlayer play];
//    [_video replaceTheResources:urlPath];
}

//获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentVC
{
    UIViewController *result = nil;
    
    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    if (window.windowLevel != UIWindowLevelNormal)
    {
        NSArray *windows = [[UIApplication sharedApplication] windows];
        for(UIWindow * tmpWin in windows)
        {
            if (tmpWin.windowLevel == UIWindowLevelNormal)
            {
                window = tmpWin;
                break;
            }
        }
    }
    
    UIView *frontView = [[window subviews] objectAtIndex:0];
    id nextResponder = [frontView nextResponder];
    
    if ([nextResponder isKindOfClass:[UIViewController class]])
        result = nextResponder;
    else
        result = window.rootViewController;
    
    return result;
}
#pragma mark - 手势相关
//单击
- (void) handleTap: (UITapGestureRecognizer *) sender
{
    if (sender.state == UIGestureRecognizerStateEnded) {
        if (sender == tapGestureRecognizer) {
            [self showHUD: _hiddenHUD];
        } else if (sender == doubleTapGestureRecognizer) {
  
        }
    }
}
//拖动
-(void)panImageView:(UIPanGestureRecognizer *)panGR
{
    [self showHUD:NO];
    CGPoint translation = [panGR translationInView:self.view];
    panGR.view.center = CGPointMake(panGR.view.center.x+translation.x,panGR.view.center.y+translation.y);
    [panGR setTranslation:CGPointZero inView:self.view];
    
    if (panGR.state==UIGestureRecognizerStateEnded)
    {
        [self changeFrameForGestureView:panGR.view];
    }
}

/**
  *  处理捏合手势
  *
  *  @param recognizer 捏合手势识别器对象实例
  */
- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
    
    CGFloat scale = recognizer.scale;
    
    //放大情况
    if(scale > 1.0){
        if(self.totalScale > MaxScale) return;
    }
    
    //缩小情况
    if (scale < 1.0) {
        if (self.totalScale < MinScale) return;
    }
    
    recognizer.view.transform = CGAffineTransformScale(recognizer.view.transform, scale, scale);
    self.totalScale *=scale;
    recognizer.scale = 1.0;

}
//调整手势view的frame
-(void)changeFrameForGestureView:(UIView *)view
{
    CGSize screenSize     = self.view.bounds.size;//[[UIScreen mainScreen] bounds].size;
    int blackViewHeight   = (screenSize.height - _oldImageViewFrame.size.height)/2;
    
    CGRect frame = view.frame;
    
    if ( frame.origin.x > 0 )
    {
        frame.origin.x=0;
    }
    if ( frame.origin.y > blackViewHeight )
    {
        frame.origin.y=blackViewHeight;
    }
    if ( CGRectGetMaxX(frame) < screenSize.width )
    {
        frame.origin.x=frame.origin.x + ( screenSize.width - CGRectGetMaxX(frame) );
    }
    if ( frame.size.width < screenSize.width)
    {
        frame.origin.x = (screenSize.width - frame.size.width)/2;
    }
    
    if ( CGRectGetMaxY(frame) < ( screenSize.height - blackViewHeight ) )
    {
        frame.origin.y = frame.origin.y + ( screenSize.height - blackViewHeight - CGRectGetMaxY(frame) );
    }
    /*
     if (frame.origin.x>0) {
     frame.origin.x=0;
     }
     if (frame.origin.y>BlackViewHeight) {
     frame.origin.y=BlackViewHeight;
     }
     if (CGRectGetMaxX(frame)<SWidth) {
     frame.origin.x=frame.origin.x+(SWidth-CGRectGetMaxX(frame));
     }
     if (CGRectGetMaxY(frame)<(SHeight-BlackViewHeight)) {
     frame.origin.y=frame.origin.y+(SHeight-BlackViewHeight-CGRectGetMaxY(frame));
     }
     */
    [UIView animateWithDuration:0.25 animations:^{
        view.frame=frame;
    }];
    
}

#pragma mark imageView Scale Operation

//imageView添加手势


- (void)ScaleToOriginal {
    [UIView animateWithDuration:0.25 animations:^{
        self->_movieView.frame = self->_oldImageViewFrame;
    }];
    [frame_x1 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [frame_x2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [frame_x3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)ScaleToDouble {
    CGSize oldSize = _oldImageViewFrame.size;
    
    CGSize newSize = CGSizeMake(oldSize.width * 2, oldSize.height * 2);
    
    CGRect frame = _oldImageViewFrame;
    
    frame.size = newSize;
    
    
    [UIView animateWithDuration:0.25 animations:^{
        self->_movieView.frame = frame;
    }];
    [frame_x1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [frame_x2 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    [frame_x3 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)ScaleToTriple {
        CGSize oldSize = _oldImageViewFrame.size;
    
        CGSize newSize = CGSizeMake(oldSize.width * 3, oldSize.height * 3);
        CGRect frame = _oldImageViewFrame;
    
        frame.size = newSize;
    
        [UIView animateWithDuration:0.25 animations:^{
            self->_movieView.frame = frame;
        }];
        [frame_x1 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [frame_x2 setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [frame_x3 setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    
}

- (void)pauseDidTouch {
    pause.selected = !pause.selected;
    if (self.mediaPlayer.isPlaying) {
        [self.mediaPlayer pause];
    } else {
        [self.mediaPlayer play];
    }
//    
//    pause.selected = !pause.selected;
//    if (playing) {
//        [_nextFrameTimer setFireDate:[NSDate distantFuture]];
//        playing = NO;
//    }
//    else {
//         [_nextFrameTimer setFireDate:[NSDate distantPast]];
//        playing = YES;
//    }
}

- (NSString *)getUrlPath{
    return  self.playUrl;
//    NSMutableDictionary *dict = [_videosArray objectAtIndex:selIdx];
//    if ([[dict allKeys]containsObject:@"bigPath"]) {
//        return [dict objectForKey:@"bigPath"];
//    }
//    else if ([[dict allKeys]containsObject:@"smallPath"]) {
//        return [dict objectForKey:@"smallPath"];
//    }
//    return nil;
}

//支持的方向
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}
////是否可以旋转
- (BOOL)shouldAutorotate
{
    return NO;
}
// 画面一开始加载时就是横向
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
