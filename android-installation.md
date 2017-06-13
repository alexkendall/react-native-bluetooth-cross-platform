# Android Installation

1.\) npm install --save react-native-bluetooth-cross-platform

2.\) Under settings.gradle, add the following:

```
include ':react-native-bluetooth-cross-platform'
project(':react-native-bluetooth-cross-platform').projectDir = new File(rootProject.projectDir, '../node_modules/react-native-bluetooth-cross-platform/android')
```

3.\) Under your project level build.gradle under repositories add the underdark dependency

```
repositories {
    mavenLocal()
    jcenter()
    maven {
        // All of React Native (JS, Obj-C sources, Android binaries) is installed from npm
        url "$rootDir/../node_modules/react-native/android"
    }
    maven {
        url 'https://dl.bintray.com/underdark/android/'
    }
}
```

4.\) Under your app level build.gradle, add the following:

```
dependencies {
    ...
    compile project(':react-native-bluetooth-cross-platform')
}
```

5.\) Under MainApplication.java add the following import to the top of the file:

```
import com.rctunderdark.NetworkManagerPackage;
```

and under getPackages add the NetworkManagerPackage:

```
protected List<ReactPackage> getPackages() {
      return Arrays.<ReactPackage>asList(
          new MainReactPackage(),..., new NetworkManagerPackage()
      );
    }
```

# 



