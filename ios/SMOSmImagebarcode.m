
#import "SMOSmImagebarcode.h"
#import "JGProgressHUDheaders/JGProgressHUD.h"

@interface SMOSmImagebarcode ()
{
    JGProgressHUDInteractionType _interaction;
    NSString* _loaddingText;
    JGProgressHUD *_loading;
}

@property (nonatomic, copy) RCTResponseSenderBlock mCallback;

@end

@implementation SMOSmImagebarcode

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _loading = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleDark];
        _loading.interactionType = _interaction;
        _loading.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
    }
    return self;
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

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *pickImage = info[UIImagePickerControllerEditedImage];
    NSData *imageData = UIImagePNGRepresentation(pickImage);
    CIImage *ciImage = [CIImage imageWithData:imageData];
    
    JGProgressHUD *HUD = _loading;
    
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
            //这段二维码的作用是是解决gbk乱码的作用
            NSString *tempStr;
            NSString *text=result.messageString;//返回的扫描结果
            //修正扫描出来二维码里有中文时为乱码问题
            if ([text canBeConvertedToEncoding:NSShiftJISStringEncoding])
            {
                tempStr = [NSString stringWithCString:[text cStringUsingEncoding:NSShiftJISStringEncoding] encoding:NSUTF8StringEncoding];
                
                //如果转化成utf-8失败，再尝试转化为gbk
                if (tempStr == nil)
                {
                    tempStr = [NSString stringWithCString:[text cStringUsingEncoding:NSShiftJISStringEncoding] encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
                }
            }
            else if([text canBeConvertedToEncoding:NSISOLatin1StringEncoding])
            {
                tempStr = [NSString stringWithCString:[text cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:NSUTF8StringEncoding];
                
                //如果转化成utf-8失败，再尝试转化为gbk
                if (tempStr == nil)
                {
                    tempStr = [NSString stringWithCString:[text cStringUsingEncoding:NSISOLatin1StringEncoding] encoding:CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000)];
                }
            }
            if (tempStr == nil)
            {
                tempStr = text;
            }
            _mCallback(@[@{@"result":tempStr}]);
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

+ (BOOL)requiresMainQueueSetup
{
    return YES;
}

@end

