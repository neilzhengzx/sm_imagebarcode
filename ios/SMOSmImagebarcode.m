
#import "SMOSmImagebarcode.h"
#import "JGProgressHUDheaders/JGProgressHUD.h"

static JGProgressHUD *LOADDING;

@interface SMOSmImagebarcode ()
{
    JGProgressHUDStyle _style;
    JGProgressHUDInteractionType _interaction;
    NSString* _loaddingText;
}

@property (nonatomic, copy) RCTResponseSenderBlock mCallback;
@property (nonatomic, copy) JGProgressHUD *HUD;
@property (nonatomic, copy) NSTimer* mTimer;

@end

@implementation SMOSmImagebarcode

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(barcodeFromImage:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    //barcodeFromImage 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    _mCallback = callback;
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    imagePicker.delegate = self;
    
    imagePicker.allowsEditing = true;
    
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:imagePicker animated:YES completion:nil];
}

RCT_EXPORT_METHOD(showLoadding:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    //showLoadding 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    
    _loaddingText = [params objectForKey:@"message"];
    
    if(_mTimer)
    {
        [_mTimer invalidate];
    }
    _mTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(delayMethod) userInfo:nil repeats:NO];
}

- (void)delayMethod
{
    JGProgressHUD *HUD = self.prototypeHUD;
    
    HUD.textLabel.text = _loaddingText;
    
    if( ![HUD isVisible]){
        UIView *topView = [[[UIApplication sharedApplication].keyWindow subviews] lastObject];
        [HUD showInView:topView];
    }
    
    [HUD dismissAfterDelay:30.0];
    
    HUD.marginInsets = UIEdgeInsetsMake(0.0f, 0.0f, 10.0f, 0.0f);
}

RCT_EXPORT_METHOD(dimissLoadding:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback)
{
    //dimissLoadding 实现, 需要回传结果用callback(@[XXX]), 数组参数里面就一个NSDictionary元素即可
    if(_mTimer)
    {
        [_mTimer invalidate];
        _mTimer = nil;
    }
    JGProgressHUD *HUD = self.prototypeHUD;
    [HUD dismiss];
}

- (JGProgressHUD *)prototypeHUD {
    if(LOADDING == NULL)
    {
        LOADDING = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        LOADDING.interactionType = _interaction;
        LOADDING.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
    }
    
    return LOADDING;
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *pickImage = info[UIImagePickerControllerEditedImage];
    NSData *imageData = UIImagePNGRepresentation(pickImage);
    CIImage *ciImage = [CIImage imageWithData:imageData];
    
    JGProgressHUD *HUD = self.prototypeHUD;
    
    HUD.textLabel.text = @"正在识别...";
    
    [HUD showInView:[UIApplication sharedApplication].keyWindow.rootViewController.view];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        HUD.indicatorView = nil;
        
        //        HUD.textLabel.font = [UIFont systemFontOfSize:30.0f];
        
        HUD.textLabel.text = @"未找到对应的条码";
        
        HUD.position = JGProgressHUDPositionCenter;
    });
    
    HUD.marginInsets = UIEdgeInsetsMake(0.0f, 0.0f, 10.0f, 0.0f);
    
    
    [picker dismissViewControllerAnimated:YES completion:^{
        //创建探测器
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy: CIDetectorAccuracyLow}];
        NSArray *feature = [detector featuresInImage:ciImage];
        
        //取出探测到的数据
        for (CIQRCodeFeature *result in feature) {
            [HUD dismiss];
            _mCallback(@[@{@"result":result.messageString}]);
            return;
        }
        
        [HUD dismissAfterDelay:1.0];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES
                               completion:nil];
}

@end

