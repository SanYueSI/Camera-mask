# Camera-mask
这个是swfit开发的

效果图

![效果图](https://imgconvert.csdnimg.cn/aHR0cHM6Ly91cGxvYWQtaW1hZ2VzLmppYW5zaHUuaW8vdXBsb2FkX2ltYWdlcy8xMzkzNDc2OS03ZDc0NTUwMjViYTNkOTM1LmpwZw?x-oss-process=image/format,png
)
使用方法

1.把 ScannerVC.framework拖动到项目 记住勾选create groups

2.引用文件 import ScannerVC

3.跳转到相机并回调
```
let vc = ScannerVC()
        vc.callback = { image in
            print(image)
            //image 返回的图片
            self.idImage = image
           
        }
        self.navigationController?.pushViewController(vc, animated: true);
```
