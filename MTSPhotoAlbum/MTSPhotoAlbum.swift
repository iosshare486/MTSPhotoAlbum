//
//  MTSPhotoAlbum.swift
//  MJSports
//
//  Created by 彩球 on 2018/7/11.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit
import Photos

extension Bundle {
    
    class func MTSPhotoAlbumBundle() -> Bundle? {
        
        if MTSPhotoAlbum.default.imgBundle != nil {
            return MTSPhotoAlbum.default.imgBundle!
        } else {
            return Bundle.getDefaultBundle()
        }
    }
    
    
    class func getDefaultBundle() -> Bundle? {
        let defaultBundleName = "KMTSNPhotoAlbum"
        if let path = Bundle(for: MTSPhotoLibraryViewController.self).path(forResource: defaultBundleName, ofType: "bundle") {
            return Bundle(path: path)
        }
        return nil
    }
    
}

extension String {
    
    func MTSPhotoAlbumLocalizedString() -> String {
        
         return NSLocalizedString(self, tableName: "MTSPhotoAlbumLocalize", bundle: Bundle(for: MTSPhotoLibraryViewController.self), value: "", comment: "")
    }
}

public class MTSPhotoAlbum: NSObject {
    
    @objc public static let `default` = MTSPhotoAlbum()
    
    private override init() {}
    
    /// 图片回调
    @objc open var electedImgs: (([UIImage]) -> Void)?
    /// 相册预览是否支持相机 (默认支持)
    @objc open var supportCamera: Bool = true
    
    ///
    @objc open var imgBundle: Bundle?
    @objc open var imgSelectName: String = "photo_preview_select"
    @objc open var imgUnselectName: String = "photo_preview_unselect"
    
    @objc open var imgCameraName: String = "photo_camera_icon"
    @objc open var doneButtonEnableColor = "0xfc5a5a".ts.color()
    
    /// 选择图片个数
    var imgLimitCount: Int = 1
    /// 相册权限
    var photoAuthorizeStatus: PHAuthorizationStatus = PHAuthorizationStatus.notDetermined
    /// 相册权限异步通知
    let photoAuthorizeNotificationName = "MTSPhotoLibraryAuthorizeChangeNotificationName"
    
    /// 检测相册读取权限
    func checkPhotoLibraryAuthorization() {
        let photoAuthStatus = PHPhotoLibrary.authorizationStatus()
        if photoAuthStatus == PHAuthorizationStatus.notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                if status == PHAuthorizationStatus.authorized {
                    // 允许使用
                    self.photoAuthorizeStatus = .authorized
                } else {
                    // 不允许使用
                    self.photoAuthorizeStatus = .denied
                }
                NotificationCenter.default.post(name: NSNotification.Name.init(self.photoAuthorizeNotificationName), object: nil)
            }
        } else {
            photoAuthorizeStatus = photoAuthStatus
        }
    }
    
    /// 调用相册
    ///
    /// - Parameters:
    ///   - launchViewController: 启动控制器
    ///   - imageLimit: 选择图片数量
    @objc open class func callPhotoAlbum(launchViewController: UIViewController, imageLimit: Int) {
        
        MTSPhotoAlbum.default.checkPhotoLibraryAuthorization()
        
        MTSPhotoAlbum.default.imgLimitCount = imageLimit
        
        let photoVC = MTSPhotoLibraryViewController()
        let previewVC = MTSPhotoPreviewViewController()
        
        let navi = UINavigationController(rootViewController: photoVC)
        navi.viewControllers.append(previewVC)
        
        launchViewController.present(navi, animated: true, completion: nil)
    }
    
    
    /// 获取所有相册
    func fetchAllPhotoAlbum() -> [MTSAlbumItem] {
        var allAlbum: [MTSAlbumItem] = [MTSAlbumItem]()
        
        let smartAlbums:PHFetchResult = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        allAlbum.append(contentsOf: convertCollection(collection: smartAlbums as! PHFetchResult<AnyObject>))
        
        let userCollections: PHFetchResult = PHCollectionList.fetchTopLevelUserCollections(with: nil)
        allAlbum.append(contentsOf: convertCollection(collection: userCollections as! PHFetchResult<AnyObject>))
        
        // 排序
        allAlbum.sort { (item1, item2) -> Bool in
            return item1.fetchResult.count > item2.fetchResult.count
        }
        return allAlbum
    }
    
    //获取相册中图片
    private func convertCollection(collection:PHFetchResult<AnyObject>) -> [MTSAlbumItem] {
        var tmpItems = [MTSAlbumItem]()
        for i in 0..<collection.count{
            //获取出当前相簿内的图片
            let resultsOptions = PHFetchOptions()
            resultsOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate",
                                                               ascending: false)]
            resultsOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
            guard let c = collection[i] as? PHAssetCollection else { return tmpItems }
            
            let assetsFetchResult = PHAsset.fetchAssets(in: c, options: resultsOptions)
            //没有图片的空相簿不显示
            if assetsFetchResult.count > 0{
                tmpItems.append(MTSAlbumItem(title: c.localizedTitle, fetchResult: assetsFetchResult as! PHFetchResult<AnyObject>))
            }
        }
        
        return tmpItems
        
    }
    
}
