# phasetida_flutter
[![Version](https://img.shields.io/badge/version-0.1.7-red.svg)]()  
[phasetida-node-demo](https://github.com/phasetida/phasetida-node-demo)的Flutter包装，使用了[flutter_inappwebview](https://pub.dev/packages/flutter_inappwebview)包装

## 安装
### 引用Github仓库
1. 在``pubspec.yaml``里添加依赖
   ```yaml
   dependencies:
   # ...
   phasetida_flutter:
     git: https://github.com/phasetida/phasetida_flutter.git
   ```
2. 运行命令来更新项目
   ```bash
   flutter pub get
   ```

## 使用
这个包添加了一个Widget，即``PhigrosChartPlayerShellWidget``和``PhigrosChartPlayerWidget``，前者为后者的包装，推荐使用前者。简单的使用方法大致如下：
```dart
PhigrosChartPlayerShellWidget(
    jsonData: /* add your chart json data here*/,
    port: 11451 /* the port of local server */,
    songName: /* for ui display */,
    author: /* for ui display */,
    chartComposer: /* for ui display */,
    quitCallback: () { /* the behavior of clicking back button in widget*/
      Navigator.pop(context);
    },
)
```
如果想要更加精细的控制，请包装``PhigrosChartPlayerWidget``，并参考[phasetida-node-demo](https://github.com/phasetida/phasetida-node-demo)在``window``里定义的函数来添加自定义Javascript交互

## 贡献者
感谢以下贡献者对这个项目做出的贡献  
|||
|:-:|:-:|
|[![](https://github.com/qianmo2233.png/?size=128)](https://github.com/qianmo2233)|
|[@qianmo2233](https://github.com/qianmo2233)|
|拯救了这个包原先丑陋的UI||