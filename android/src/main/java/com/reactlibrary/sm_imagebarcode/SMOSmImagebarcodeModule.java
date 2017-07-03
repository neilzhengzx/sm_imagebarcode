
package com.reactlibrary.sm_imagebarcode;

import android.Manifest;
import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.Cursor;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;
import android.provider.MediaStore;
import android.support.v4.app.ActivityCompat;
import android.support.v4.content.ContextCompat;
import android.widget.Toast;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.BinaryBitmap;
import com.google.zxing.DecodeHintType;
import com.google.zxing.LuminanceSource;
import com.google.zxing.MultiFormatReader;
import com.google.zxing.NotFoundException;
import com.google.zxing.Result;
import com.google.zxing.common.HybridBinarizer;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Hashtable;
import java.util.Vector;

public class SMOSmImagebarcodeModule extends ReactContextBaseJavaModule implements ActivityEventListener {

  private final ReactApplicationContext reactContext;
  private static Activity mCurrentActivety;
  private static final int ACTIVITY_RESULT_FOR_PHOTO = 101;
  private static final int REQUEST_CODE_ASK_CAMERA_ZXING = 102;
  private Callback mCallBack;

  public SMOSmImagebarcodeModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    reactContext.addActivityEventListener(this);
  }

  @Override
  public String getName() {
    return "SMOSmImagebarcode";
  }
  
  
  @ReactMethod
  public void barcodeFromImage(ReadableMap params, Callback callback){
    // barcodeFromImage 实现, 返回参数用WritableMap封装, 调用callback.invoke(WritableMap)

    mCallBack = callback;

    mCurrentActivety = getCurrentActivity();
    if (mCurrentActivety == null) {
      return;
    }

    if(ContextCompat.checkSelfPermission(mCurrentActivety, Manifest.permission.READ_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED
            || ContextCompat.checkSelfPermission(mCurrentActivety, Manifest.permission.WRITE_EXTERNAL_STORAGE) != PackageManager.PERMISSION_GRANTED)
    {
      if (ActivityCompat.shouldShowRequestPermissionRationale(mCurrentActivety, Manifest.permission.READ_EXTERNAL_STORAGE)
              || ActivityCompat.shouldShowRequestPermissionRationale(mCurrentActivety, Manifest.permission.WRITE_EXTERNAL_STORAGE))
      {
        mCurrentActivety.runOnUiThread(new Runnable() {
          @Override
          public void run() {
            Toast.makeText(mCurrentActivety,
                    "未给予相册权限，请在手机设置－应用权限中修改",
                    Toast.LENGTH_LONG).show();
          }
        });
      }
      return;
    }

    Intent intent = new Intent(Intent.ACTION_PICK, android.provider.MediaStore.Images.Media.EXTERNAL_CONTENT_URI);
    mCurrentActivety.startActivityForResult(intent, ACTIVITY_RESULT_FOR_PHOTO);
  }

  public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent intent) {
    if (resultCode == activity.RESULT_OK) {
      switch (requestCode) {
        case ACTIVITY_RESULT_FOR_PHOTO:
        {
          if (intent!=null){
            Uri uri = intent.getData();
            //                      Bundle extras = data.getExtras();
            if (uri!=null) {
              String[] filePathColumn = {MediaStore.Images.Media.DATA};

              Cursor cursor = mCurrentActivety.getContentResolver().query(uri, filePathColumn, null, null, null);
              cursor.moveToFirst();

              int columnIndex = cursor.getColumnIndex(filePathColumn[0]);
              final String path = cursor.getString(columnIndex);
              cursor.close();

              new Thread(new Runnable() {

                @Override
                public void run() {
                  startParseBitmap(path);

                }
              }).start();
              //                        Bitmap currentBitmap = safeDecodeStream(path);

            }
          }
        }
          break;
        default:
          break;
      }
    }
  }

  public void onNewIntent(Intent intent) {
  }

  private void startParseBitmap(String path)
  {
    MultiFormatReader multiFormatReader = new MultiFormatReader();

    //解码的参数

    Hashtable<DecodeHintType, Object> hints = new Hashtable<DecodeHintType, Object>(2);

    // 可以解析的编码类型


    Vector<BarcodeFormat> decodeFormats = new Vector<BarcodeFormat>();

    if (decodeFormats == null || decodeFormats.isEmpty()) {
      decodeFormats = new Vector<BarcodeFormat>();

      //这里设置可扫描的类型，我这里选择了都支持
      decodeFormats.addAll(DecodeFormatManager.AZTEC_FORMATS);
      decodeFormats.addAll(DecodeFormatManager.QR_CODE_FORMATS);
      decodeFormats.addAll(DecodeFormatManager.DATA_MATRIX_FORMATS);
      decodeFormats.addAll(DecodeFormatManager.PRODUCT_FORMATS);
      decodeFormats.addAll(DecodeFormatManager.INDUSTRIAL_FORMATS);

      hints.put(DecodeHintType.POSSIBLE_FORMATS, decodeFormats);
      //设置继续的字符编码格式为 UTF8
      // hints.put(DecodeHintType.CHARACTER_SET, "UTF8");
      //设置解析配置参数

      multiFormatReader.setHints(hints);
      //开始对图像资源解码

      Result rawResult = null;
      try {
        Bitmap bitmap = safeDecodeStream(path);
        LuminanceSource source = new BitmapLuminanceSource(bitmap);

        BinaryBitmap bit = new BinaryBitmap(new HybridBinarizer(source));
        rawResult = multiFormatReader.decodeWithState(bit);

      } catch (NotFoundException e) {
        e.printStackTrace();
      } catch (FileNotFoundException e) {
        // TODO 自动生成的 catch 块
        e.printStackTrace();
      }
      if(rawResult != null && rawResult.getText() != null){

        WritableMap response = Arguments.createMap();
        response.putString("result", rawResult.getText() );
        mCallBack.invoke(response);
      } else {
        mCurrentActivety.runOnUiThread(new Runnable() {

          @Override
          public void run() {
            Toast.makeText(mCurrentActivety,
                    "图片中未发现条码",
                    Toast.LENGTH_LONG).show();
          }
        });
      }
      return ;
    }
  }

  /**
   * A safer decodeStream method
   * rather than the one of {@link BitmapFactory}
   * which will be easy to get OutOfMemory Exception
   * while loading a big image file.
   *
   * @return
   * @throws FileNotFoundException
   */
  public static Bitmap safeDecodeStream(String path)
          throws FileNotFoundException{
    //获取图片的旋转角度，有些系统把拍照的图片旋转了，有的没有旋转
    int degree = readPictureDegree(path);
    int scale = 1;
    BitmapFactory.Options options = new BitmapFactory.Options();
    options.inJustDecodeBounds = true;// 设置成了true,不占用内存，只获取bitmap宽高
    BitmapFactory.decodeFile(path, options);

    // Decode with inSampleSize option
    options.inJustDecodeBounds = false;
    options.inSampleSize = computeSampleSize(options, -1,1024*800);//1024*800);
    options.inPurgeable = true;
    options.inInputShareable = true;
    options.inDither = false;
    options.inPurgeable = true;
    options.inTempStorage = new byte[16 * 1024];
    FileInputStream ip = new FileInputStream(path);
    Bitmap bmp = null;
    try {
      Bitmap b = BitmapFactory.decodeFileDescriptor(
              ip.getFD(),
              null,
              options);
      double scale2 = getScaling(options.outWidth * options.outHeight, 800*600);
      bmp = Bitmap.createScaledBitmap(b,
              (int) (options.outWidth * scale2),
              (int) (options.outHeight * scale2), true);
      b.recycle();
    } catch (IOException e1) {
      e1.printStackTrace();
    }  finally{
      try {
        ip.close();
      } catch (IOException e) {
        e.printStackTrace();
      }
    }
    bmp = rotaingImageView(degree, bmp);

    return bmp;
  }

  private static int computeInitialSampleSize(BitmapFactory.Options options,
                                              int minSideLength, int maxNumOfPixels) {
    double w = options.outWidth;
    double h = options.outHeight;
    int lowerBound = (maxNumOfPixels == -1) ? 1 :
            (int) Math.ceil(Math.sqrt(w * h / maxNumOfPixels));
    int upperBound = (minSideLength == -1) ? 128 :
            (int) Math.min(Math.floor(w / minSideLength),
                    Math.floor(h / minSideLength));
    if (upperBound < lowerBound) {
      return lowerBound;
    }
    if ((maxNumOfPixels == -1) &&
            (minSideLength == -1)) {
      return 1;
    } else if (minSideLength == -1) {
      return lowerBound;
    } else {
      return upperBound;
    }
  }


  private static double getScaling(int src, int des) {
    double scale = Math.sqrt((double) des / (double) src);
    return scale;
  }
  public static int computeSampleSize(BitmapFactory.Options options,
                                      int minSideLength, int maxNumOfPixels) {
    int initialSize = computeInitialSampleSize(options, minSideLength,
            maxNumOfPixels);

    int roundedSize;
    if (initialSize <= 8) {
      roundedSize = 1;
      while (roundedSize < initialSize) {
        roundedSize <<= 1;
      }
    } else {
      roundedSize = (initialSize + 7) / 8 * 8;
    }

    return roundedSize;
  }

  /**
   * 读取图片属性：旋转的角度
   * @param path 图片绝对路径
   * @return degree旋转的角度
   */
  public static int readPictureDegree(String path) {
    int degree  = 0;
    try {
      ExifInterface exifInterface = new ExifInterface(path);
      int orientation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
      switch (orientation) {
        case ExifInterface.ORIENTATION_ROTATE_90:
          degree = 90;
          break;
        case ExifInterface.ORIENTATION_ROTATE_180:
          degree = 180;
          break;
        case ExifInterface.ORIENTATION_ROTATE_270:
          degree = 270;
          break;
      }
    } catch (IOException e) {
      e.printStackTrace();
    }
    return degree;
  }


  /**
   * 旋转图片
   * @param angle
   * @param bitmap
   * @return Bitmap
   */
  public static Bitmap rotaingImageView(int angle , Bitmap bitmap) {
    //旋转图片 动作
    Matrix matrix = new Matrix();
    matrix.postRotate(angle);
    System.out.println("angle2=" + angle);
    // 创建新的图片
    Bitmap resizedBitmap = Bitmap.createBitmap(bitmap, 0, 0,
            bitmap.getWidth(), bitmap.getHeight(), matrix, true);
    return resizedBitmap;
  }

  public class BitmapLuminanceSource extends LuminanceSource {

    private byte bitmapPixels[];

    protected BitmapLuminanceSource(Bitmap bitmap) {
      super(bitmap.getWidth(), bitmap.getHeight());

      // 首先，要取得该图片的像素数组内容
      int[] data = new int[bitmap.getWidth() * bitmap.getHeight()];
      this.bitmapPixels = new byte[bitmap.getWidth() * bitmap.getHeight()];
      bitmap.getPixels(data, 0, getWidth(), 0, 0, getWidth(), getHeight());

      // 将int数组转换为byte数组，也就是取像素值中蓝色值部分作为辨析内容
      for (int i = 0; i < data.length; i++) {
        this.bitmapPixels[i] = (byte) data[i];
      }
    }

    @Override
    public byte[] getMatrix() {
      // 返回我们生成好的像素数据
      return bitmapPixels;
    }

    @Override
    public byte[] getRow(int y, byte[] row) {
      // 这里要得到指定行的像素数据
      System.arraycopy(bitmapPixels, y * getWidth(), row, 0, getWidth());
      return row;
    }
  }
}