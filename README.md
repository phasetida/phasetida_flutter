# phasetida_flutter
[![Version](https://img.shields.io/badge/version-0.3.1-red.svg)]()  
[phasetida-core](https://github.com/phasetida/phasetida-core)的Flutter包装

## 安装
### 引用Github仓库
1. 在``pubspec.yaml``里添加依赖
   ```yaml
   dependencies:
   # ...
   phasetida_flutter:
     git: https://github.com/phasetida/phasetida_flutter.git
     ref: "0.3.1"
   ```
2. 运行命令来更新项目
   ```bash
   flutter pub get
   ```

## 使用
这个包添加了两个Widget，即``PhigrosChartPlayerShellWidget``和``PhigrosSimulatorRenderWidget``，前者为后者的包装，推荐使用前者。
如果想要更加精细的控制，请包装``PhigrosSimulatorRenderWidget``

## 贡献者
感谢以下贡献者对这个项目做出的贡献  
|||
|:-:|:-:|
|[![](https://github.com/qianmo2233.png/?size=128)](https://github.com/qianmo2233)|
|[@qianmo2233](https://github.com/qianmo2233)|
|拯救了这个包原先丑陋的UI和糟糕的用户体验|