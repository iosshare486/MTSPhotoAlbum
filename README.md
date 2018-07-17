# MTSPhotoAlbum
#### 系统相册支持多选

## Usage

### Info.plist配置
```
	<key>NSCameraUsageDescription</key>
	<string>需要相机权限</string>
	<key>NSPhotoLibraryUsageDescription</key>
	<string>需要照片权限</string>
	<key>NSPhotoLibraryAddUsageDescription</key>
	<string>需要访问媒体资料库</string>
```


### 常规使用

```
/**
 * function: 唤起相册
 * launchViewController: 启动依赖控制器
 * imageLimit: 选择图片数量限制
 */
MTSPhotoAlbum.callPhotoAlbum(launchViewController: launch, imageLimit: count)

/** 图片回调 */
MTSPhotoAlbum.default.electedImgs = { (imgs) in
	// imgs: 图片数组回调
}

/// 配置图片列表同时支持相机 (默认开启)
MTSPhotoAlbum.default.supportCamera = true


```

### 支持自定义UI

```
// 自定义图片资源Bundle
var imgBundle: Bundle
// 自定义已选择图片Icon
var imgSelectName: String = "photo_preview_select"
// 自定义未选择图片Icon
var imgUnselectName: String = "photo_preview_unselect"
// 自定义相机图片 (MTSPhotoAlbum.default.supportCamera设置为true时生效)    
var imgCameraName: String = "photo_camera_icon"
// 自定义完成按钮可用状态颜色
var doneButtonEnableColor = "0xfc5a5a".ts.color()
// 自定义无图片权限时,提示文字内容
var photoAuthorizeDeniedMessage = "请在iPhone的“设置-隐私-照片”选项中,\n允许访问你的手机相册"

PS: 自定义图片需存放至自定义 imgBundle中

```

## For Objective-C
```

1. Build Settings中 修改 Defines Module 设置为YES
2. 在需要使用的类中输入 #import <MTSPhotoAlbum/MTSPhotoAlbum-Swift.h>
3. Podfile顶部需设置 use_frameworks!
重新编译即可
```