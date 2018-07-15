//
//  MTSPhotoPreviewViewController.swift
//  MJSports
//
//  Created by 彩球 on 2018/7/11.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit
import Photos

enum MTSPhotoPreviewMType {
    case image, camera
}

class MTSPhotoPreviewM {
    var asset: PHAsset?
    var type: MTSPhotoPreviewMType = .image
    var isUseOriginImg: Bool = false
    var previewOriginFrame: CGRect?
    
    init(type: MTSPhotoPreviewMType = .image) {
        self.type = type
    }
}

class MTSPhotoPreviewViewController: UIViewController {

    /// 某一个相册内图片数据源
    var photoAlbrum: PHFetchResult<AnyObject>?
    /// 相册名称
    var photoTitle: String?
    /// 多选数量限制
    var imgSelectLimit = MTSPhotoAlbum.default.imgLimitCount
    /// 列表中是否支持相机
    var supportCamera: Bool = MTSPhotoAlbum.default.supportCamera
    
    private let photoPreviewCellId = "MTSPhotoPreviewCellId"
    private let photoCameraCellId = "MTSPhotoCameraCellId"
    private var photoCollectionView: UICollectionView!
    private var photoToolBar: MTSPhotoPreviewToolBar!
    private var imageManager: PHCachingImageManager!
    
    /// 被选中IndexPath存放数组
    private var selectedIndexs = [Int]()
    /// 列表展示数组
    private var showArr = [MTSPhotoPreviewM]()
    
    private var uploadImgs = [UIImage]()
    private var cancelBtn = UIButton()
    private var goBackBtn = UIButton()
    
    
    private var photoAuthorizeView: MTSPhotoLibraryAuthorizeView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        addNotificationObserver()
        
        imageManager = PHCachingImageManager()
        
        cancelBtn.setTitle("取消", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.ts.scale())
        cancelBtn.setTitleColor("0x6".ts.color(), for: .normal)
        cancelBtn.addTarget(self, action: #selector(closePhotolibrary), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelBtn)
        
        goBackBtn.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
        goBackBtn.setImage(UIImage(named: "photo_left_back", in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil), for: .normal)
        goBackBtn.addTarget(self, action: #selector(goBackViewController), for: .touchUpInside)
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: goBackBtn)
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        
        photoCollectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        photoCollectionView.backgroundColor = .white
        photoCollectionView.register(MTSPhotoPreviewCell.self, forCellWithReuseIdentifier: photoPreviewCellId)
        photoCollectionView.register(MTSPhotoCameraCell.self, forCellWithReuseIdentifier: photoCameraCellId)
        
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        
    
        
        view.addSubview(photoCollectionView)
        
        photoToolBar = MTSPhotoPreviewToolBar(frame: .zero)
        photoToolBar.toolBarDoneExecute = {
            self.finishSelectExecute()
        }
        view.addSubview(photoToolBar)
        
        let height = UIDevice().ts.isIPhoneX ? 69.ts.scale() : 49.ts.scale()
        
        photoToolBar.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(height)
        }
        
        photoCollectionView.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            make.bottom.equalTo(photoToolBar.snp.top)
        }
        
        initAuthorizeViews()
        
    }
    /// 关闭相册
    @objc private func closePhotolibrary() {
        dismiss(animated: true, completion: nil)
    }
    
    /// 返回上一层
    @objc private func goBackViewController() {
        navigationController?.popViewController(animated: true)
    }
    
    
    /// 预处理数据
    private func prepareConfigureDatas() {
        if MTSPhotoAlbum.default.photoAuthorizeStatus == .authorized {
            resetCachedAssets()
        }
        
        if supportCamera && MTSPhotoAlbum.default.photoAuthorizeStatus == .authorized {
            showArr.append(MTSPhotoPreviewM(type: .camera))
        }
        
        if photoAlbrum == nil {
            prepareAlbum()
        }
        self.title = photoTitle
        if photoAlbrum == nil || photoAlbrum!.count == 0 {
            return
        }
        
        let total = photoAlbrum!.count - 1
        
        for i in 0...total {
            let M = MTSPhotoPreviewM()
            M.asset = photoAlbrum![i] as? PHAsset
            showArr.append(M)
        }
        
        photoCollectionView.reloadData()
        
        syncToolBarStatus()
    }
    
    /// 清除缓存
    private func resetCachedAssets() {
        
        imageManager.stopCachingImagesForAllAssets()
    }
    
    
    /// 同步ToolBar状态
    private func syncToolBarStatus() {
        photoToolBar.configureSelectImgCount(selectedIndexs.count)
    }
    
    /// ToolBar Execute
    private func finishSelectExecute() {
        uploadImgs.removeAll()
        for idx in selectedIndexs {
            let M = showArr[idx]
            imageManager.requestImage(for: M.asset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) { (img, info) in
                if img != nil {
                    self.uploadImgs.append(img!)
                    self.checkFinishImgDown()
                }
            }
        }
    }
    
    private func checkFinishImgDown() {
        if uploadImgs.count == selectedIndexs.count {
            MTSPhotoAlbum.default.electedImgs?(uploadImgs)
            dismiss(animated: true, completion: nil)
        }
    }
    
    /// 调用照相机
    private func openCamera() {
        let sourceType = UIImagePickerControllerSourceType.camera
        if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera){
            return
//            sourceType = UIImagePickerControllerSourceType.photoLibrary
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true//设置可编辑
        picker.sourceType = sourceType
        present(picker, animated: true, completion: nil)
    }

    /// 图片点选回调
    private func imageSelectOperation(cell: UICollectionViewCell) {
        if let idxP = photoCollectionView.indexPath(for: cell) {
            if selectedIndexs.contains(idxP.row) {
                if let idx = selectedIndexs.index(of: idxP.row) {
                    selectedIndexs.remove(at: idx)
                }
            } else {
                if selectedIndexs.count < imgSelectLimit {
                    selectedIndexs.append(idxP.row)
                }
            }
            
            if selectedIndexs.count == imgSelectLimit ||
               selectedIndexs.count == (imgSelectLimit - 1) {
                //刷全部
                var tmpIndexPaths = [IndexPath]()
                for v in photoCollectionView.visibleCells {
                    if let value = photoCollectionView.indexPath(for: v) {
                        tmpIndexPaths.append(value)
                    }
                }
                photoCollectionView.reloadItems(at: tmpIndexPaths)
            } else {
                photoCollectionView.reloadItems(at: [idxP])
            }
            
            //同步底部图片选中数量,及按钮状态
            syncToolBarStatus()
            
        }
    }
    
    private func prepareAlbum() {
        let photoDatas = MTSPhotoAlbum.default.fetchAllPhotoAlbum()
        if photoDatas.count > 0 {
            photoAlbrum = photoDatas[0].fetchResult
            photoTitle = photoDatas[0].title
        }
    }
    
    
    func initAuthorizeViews() {
        
        if MTSPhotoAlbum.default.photoAuthorizeStatus == .authorized {
            
            if photoAuthorizeView != nil {
                photoAuthorizeView?.removeFromSuperview()
            }
            prepareConfigureDatas()
            goBackBtn.isHidden = false
        } else {
            goBackBtn.isHidden = true
            if photoAuthorizeView == nil {
                photoAuthorizeView = MTSPhotoLibraryAuthorizeView(frame: view.bounds)
            }
            if !view.subviews.contains(photoAuthorizeView!) {
                view.addSubview(photoAuthorizeView!)
            }
        }
    }
    
    
    @objc func photoLibraryAuthStateChange() {
        DispatchQueue.main.async { [weak self] in
            if let ws = self {
                ws.initAuthorizeViews()
            }
        }
    }
    
    private func addNotificationObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(photoLibraryAuthStateChange), name: NSNotification.Name.init(MTSPhotoAlbum.default.photoAuthorizeNotificationName), object: nil)
    }
    
    private func removeNotificationObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    deinit {
        removeNotificationObserver()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

// MARK: - UICollectionViewDelegate

extension MTSPhotoPreviewViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return showArr.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let item = showArr[indexPath.row]
        if item.type == .image {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoPreviewCellId, for: indexPath) as! MTSPhotoPreviewCell
            
            cell.selectStateChange = { [weak self] (photoCell) in
                if let ws = self {
                    ws.imageSelectOperation(cell: photoCell)
                }
            }
            
            let asset = showArr[indexPath.row].asset!
            let w = UIScreen.main.bounds.size.width / 4.0
            let size = CGSize(width: w, height: w)
            
            imageManager.requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: nil) { (img, nfo) in
                cell.imgV.image = img
            }
            cell.setSelectedState(selectedIndexs.contains(indexPath.row), canSelect: !(selectedIndexs.count == imgSelectLimit))
            
            return cell
            
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: photoCameraCellId, for: indexPath) as! MTSPhotoCameraCell
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if showArr[indexPath.row].type == .camera {
            openCamera()
        } else {
            
            var tmpIndexRect: [(Int, CGRect)] = [(Int, CGRect)]()
            for cel in collectionView.visibleCells {
                if let idx = collectionView.indexPath(for: cel) {
                    let rect = collectionView.convert(cel.frame, to: (UIApplication.shared.delegate?.window)!)
                    tmpIndexRect.append((idx.row,rect))
                }
            }
            
            for (i,m) in showArr.enumerated() {
                var hasFrame: Bool = false
                for value in tmpIndexRect {
                    if value.0 == i {
                        m.previewOriginFrame = value.1
                        hasFrame = true
                    }
                }
                
                if !hasFrame {
                    m.previewOriginFrame = nil
                }
                
            }
            
            
            var browserImgs = showArr
            var imgIndexs = selectedIndexs
            
            
            if MTSPhotoAlbum.default.supportCamera {
                browserImgs.removeFirst()
                imgIndexs = selectedIndexs.map { (v) -> Int in
                    return v - 1
                }
            }
            
            let browserVC = MTSPhotoBrowserViewController()
            browserVC.delegate = self
            browserVC.dismissAction = {
                self.navigationController?.dismiss(animated: true, completion: nil)
            }
            browserVC.backImg = (UIApplication.shared.delegate?.window as? UIView)?.MTS_ScreenShot()
            browserVC.configurePHPreviewM(data: browserImgs, selectedIndexs: imgIndexs, selectIndex: indexPath.row - 1)
            navigationController?.present(browserVC, animated: true, completion: nil)
        }
        
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let w = UIScreen.main.bounds.size.width / 4.0
        
        return CGSize(width: w, height: w)
    }
}

// MARK: - MTSPhotoBrowserViewControllerDelegate

extension MTSPhotoPreviewViewController: MTSPhotoBrowserViewControllerDelegate {
    
    func updateImgSelectIndexs(_ indexs: [Int]) {
        selectedIndexs.removeAll()
        if MTSPhotoAlbum.default.supportCamera {
            let tmpIndexs = indexs.map { (idx) -> Int in
                return idx + 1
            }
            selectedIndexs.append(contentsOf: tmpIndexs)
        } else {
            selectedIndexs.append(contentsOf: indexs)
        }
        
        photoCollectionView.reloadData()
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MTSPhotoPreviewViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {

        if let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
            MTSPhotoAlbum.default.electedImgs?([image])
        }
        
        picker.dismiss(animated: false) { [weak self] in
            if let ws = self {
                ws.dismiss(animated: true, completion: nil)
            }
        }
    }
}

// MARK: - ToolBar

class MTSPhotoPreviewToolBar: UIView {
    private var doneBtn = UIButton()
    private var countLbl = UILabel()
    
    var toolBarDoneExecute: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = "0x0".ts.color()
        
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font = 13.ts.font()
        doneBtn.clipsToBounds = true
        doneBtn.layer.cornerRadius = 4.ts.scale()
        doneBtn.addTarget(self, action: #selector(doneClicked), for: .touchUpInside)
        
        countLbl.font = 15.ts.font()
        countLbl.textColor = "0xB".ts.color()
        countLbl.textAlignment = .left
        
        doneBtn.setTitle("完成", for: .normal)
        doneBtn.backgroundColor = .green
        
        
        addSubview(doneBtn)
        addSubview(countLbl)
        
        doneBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(9.ts.scale())
            make.right.equalToSuperview().offset(-10.ts.scale())
            make.width.equalTo(60.ts.scale())
            make.height.equalTo(30.ts.scale())
        }
        
        countLbl.snp.makeConstraints { (make) in
            make.top.equalTo(doneBtn)
            make.left.equalToSuperview().offset(10.ts.scale())
            make.height.equalTo(doneBtn)
            make.width.equalTo(150.ts.scale())
        }
        
    }
    
    @objc func doneClicked() {
        toolBarDoneExecute?()
    }
    
    func configureSelectImgCount(_ count: Int) {
        let hasImg = count > 0
        
        if hasImg {
            let countStr = String(format: "%i", count)
            countLbl.text = "已选择: " + countStr
        } else {
            countLbl.text = "请选择图片"
        }
        
        doneBtn.isEnabled = hasImg
        
        doneBtn.backgroundColor = hasImg ? MTSPhotoAlbum.default.doneButtonEnableColor : .lightGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}


// MARK: - Cell
class MTSPhotoCameraCell: UICollectionViewCell {
    
    private var imgV = UIImageView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.backgroundColor = "0xF2F4F6".ts.color()
        imgV.image = UIImage(named: MTSPhotoAlbum.default.imgCameraName, in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil)
        
        contentView.addSubview(imgV)
        imgV.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.width.equalToSuperview().multipliedBy(2.0/5.0)
            make.height.equalTo(imgV.snp.width)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class MTSPhotoPreviewCell: UICollectionViewCell {
    
    var imgV = UIImageView()
    var selectFlag = UIButton()
    
    func setSelectedState(_ state: Bool, canSelect: Bool) {
        
        let unselectImg: UIImage? = UIImage(named: MTSPhotoAlbum.default.imgUnselectName, in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil)
        let selectImg: UIImage? = UIImage.init(named: MTSPhotoAlbum.default.imgSelectName, in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil)
        
        selectFlag.setImage(state ? selectImg : unselectImg, for: .normal)
        if !state {
            selectFlag.isHidden = !canSelect
        } else {
            selectFlag.isHidden = false
        }
    }
    
    var selectStateChange: ((UICollectionViewCell) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        
        contentView.addSubview(imgV)
        contentView.addSubview(selectFlag)
        selectFlag.contentEdgeInsets = UIEdgeInsets(top: 3.ts.scale(), left: 3.ts.scale(), bottom: 3.ts.scale(), right: 3.ts.scale())
        selectFlag.addTarget(self, action: #selector(flagClicked), for: .touchUpInside)
        
        selectFlag.snp.makeConstraints { (make) in
            make.top.right.equalToSuperview()
            make.width.equalTo(28.ts.scale())
            make.height.equalTo(selectFlag.snp.width)
        }
        
        imgV.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        
    }
    
    @objc func flagClicked() {
        selectStateChange?(self)
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
