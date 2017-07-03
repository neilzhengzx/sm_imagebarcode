
#import "SMOSmImagebarcode.h"
#import "ZXingObjC/ZXingObjC.h"
#import "JGProgressHUDheaders/JGProgressHUD.h"

@interface SMOSmImagebarcode ()
{
    JGProgressHUDStyle _style;
    JGProgressHUDInteractionType _interaction;
}

@property (nonatomic, copy) RCTResponseSenderBlock mCallback;

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

- (JGProgressHUD *)prototypeHUD {
    JGProgressHUD *HUD = [[JGProgressHUD alloc] initWithStyle:_style];
    HUD.interactionType = _interaction;

    HUD.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
    
    return HUD;
}

- (void)imagePickerController:(UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
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
        ZXLuminanceSource *source = [[ZXCGImageLuminanceSource alloc] initWithCGImage:image.CGImage];
        ZXBinaryBitmap *bitmap = [ZXBinaryBitmap binaryBitmapWithBinarizer:[ZXHybridBinarizer binarizerWithSource:source]];
        
        NSError *error = nil;
        
        // There are a number of hints we can give to the reader, including
        // possible formats, allowed lengths, and the string encoding.
        ZXDecodeHints *hints = [ZXDecodeHints hints];
        [hints addPossibleFormat:kBarcodeFormatAztec];
        [hints addPossibleFormat:kBarcodeFormatQRCode];
        [hints addPossibleFormat:kBarcodeFormatMaxiCode];
        
        [hints addPossibleFormat:kBarcodeFormatCode128];
        [hints addPossibleFormat:kBarcodeFormatCodabar];
        [hints addPossibleFormat:kBarcodeFormatCode93];
        [hints addPossibleFormat:kBarcodeFormatCode39];
        
        [hints addPossibleFormat:kBarcodeFormatDataMatrix];
        [hints addPossibleFormat:kBarcodeFormatPDF417];
        
        [hints addPossibleFormat:kBarcodeFormatEan13];
        [hints addPossibleFormat:kBarcodeFormatEan8];
        [hints addPossibleFormat:kBarcodeFormatUPCA];
        [hints addPossibleFormat:kBarcodeFormatUPCE];
        [hints addPossibleFormat:kBarcodeFormatRSS14];
        [hints addPossibleFormat:kBarcodeFormatRSSExpanded];
        
        
        ZXMultiFormatReader *reader = [ZXMultiFormatReader reader];
        ZXResult *result = [reader decode:bitmap
                                    hints:hints
                                    error:&error];
        
        if (result) {
            // The coded result as a string. The raw data can be accessed with
            // result.rawBytes and result.length.
            [HUD dismiss];
            [self captureResult:nil result:result];
            
        } else {
            //            NSLog(@"error = %@", error);
            [HUD dismissAfterDelay:1.0];
            
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES
                               completion:nil];
}

#pragma mark - ZXCaptureDelegate Methods

- (void)captureResult:(ZXCapture *)capture result:(ZXResult *)result {
    if (!result) return;
    
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
    [result rawBytes];
    
    _mCallback(@[@{@"result":result.text}]);
}

@end
  
