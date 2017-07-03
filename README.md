
# react-native-sm-imagebarcode

## Getting started

`$ npm install react-native-sm-imagebarcode --save`

### Mostly automatic installation

`$ react-native link react-native-sm-imagebarcode`

### Manual installation


#### iOS

1. In XCode, in the project navigator, right click `Libraries` ➜ `Add Files to [your project's name]`
2. Go to `node_modules` ➜ `react-native-sm-imagebarcode` and add `SMOSmImagebarcode.xcodeproj`
3. In XCode, in the project navigator, select your project. Add `libSMOSmImagebarcode.a` to your project's `Build Phases` ➜ `Link Binary With Libraries`
4. Run your project (`Cmd+R`)<

#### Android

1. Open up `android/app/src/main/java/[...]/MainActivity.java`
  - Add `import com.reactlibrary.sm_imagebarcode.SMOSmImagebarcodePackage;` to the imports at the top of the file
  - Add `new SMOSmImagebarcodePackage()` to the list returned by the `getPackages()` method
2. Append the following lines to `android/settings.gradle`:
  	```
  	include ':react-native-sm-imagebarcode'
  	project(':react-native-sm-imagebarcode').projectDir = new File(rootProject.projectDir, 	'../node_modules/react-native-sm-imagebarcode/android')
  	```
3. Insert the following lines inside the dependencies block in `android/app/build.gradle`:
  	```
      compile project(':react-native-sm-imagebarcode')
  	```


## Usage
```javascript
import SMOSmImagebarcode from 'react-native-sm-imagebarcode';

// TODO: What to do with the module?
SMOSmImagebarcode;
```
  