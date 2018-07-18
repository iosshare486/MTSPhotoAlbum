//
//  MTSPhotoBrowserViewController.swift
//  MJSports
//
//  Created by 彩球 on 2018/7/13.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit
import TSUtility
import Photos
import SnapKit

protocol MTSPhotoBrowserViewControllerDelegate {
    func updateImgSelectIndexs(_ indexs: [Int])
}

class MTSPhotoBrowserViewController: UIViewController {

    var backImg: UIImage?
    var delegate: MTSPhotoBrowserViewControllerDelegate?
    var dismissAction: (() -> Void)?
    
    private var backgroundMaskImageV = UIImageView()
    private var browser: UICollectionView!
    
    private var navigationBar: MTSPhotoBrowserNavigationBar!
    private var bottomToolBar: MTSPhotoBrowserToolBar!
    private var thumbnailTool: UIView!

    
    private var previewImages = [MTSPhotoPreviewM]()
    private var selectedImageIndexs = [Int]()
    
    private var isHiddenToolBar = false
    private var currentImageIndex: Int = 0
    private var uploadImgs = [UIImage]()
    private lazy var imageManager: PHCachingImageManager = {
        return PHCachingImageManager()
    }()
    
    private let collectionCellID = "MTSPhotoBrowserCollectionCellID"
    
    override func viewDidLoad() {
        
        view.backgroundColor = .white
        initViews()
        initLayouts()
        
    }
    
    
    
    func configurePHPreviewM(data: [MTSPhotoPreviewM] , selectedIndexs: [Int], selectIndex: Int) {
        currentImageIndex = selectIndex
        previewImages.removeAll()
        previewImages.append(contentsOf: data)
        selectedImageIndexs.removeAll()
        selectedImageIndexs.append(contentsOf: selectedIndexs)
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        configureViews()
    }
    
    /// 初始化UI
    private func initViews() {
        
        //background
        backgroundMaskImageV = UIImageView()
        backgroundMaskImageV.image = backImg
        view.addSubview(backgroundMaskImageV)
        
        //collectionView
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.itemSize = view.bounds.size
        flowLayout.scrollDirection = .horizontal
        
        browser = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        browser.backgroundColor = .black
        browser.delegate = self
        browser.dataSource = self
        browser.isPagingEnabled = true
        browser.register(MTSPhotoBrowserCollectionCell.self, forCellWithReuseIdentifier: collectionCellID)
        view.addSubview(browser)
        
        //navigationBar
        navigationBar = MTSPhotoBrowserNavigationBar(frame: .zero)
        
        navigationBar.gobackAction = {[weak self] in
            if let ws = self {
                ws.navigationBarGobackAction()
            }
        }
        
        navigationBar.selectAction = { [weak self] in
            if let ws = self {
                ws.navigationBarSelectStateChange()
            }
        }
        view.addSubview(navigationBar)
        
        //bottomTool
        bottomToolBar = MTSPhotoBrowserToolBar(frame: .zero)
        bottomToolBar.toolBarDoneExecute = { [weak self] in
            if let ws = self {
                ws.toolBarDoneAction()
            }
        }
        view.addSubview(bottomToolBar)
        
    }
    
    /// 初始化配置视图状态
    private func configureViews() {
        setContentOffset(idx: currentImageIndex)
        configureNavigationBar()
        configureToolBar()
    }
    
    /// 初始化约束
    private func initLayouts() {
        backgroundMaskImageV.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        browser.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        navigationBar.snp.makeConstraints { (make) in
            make.left.top.right.equalToSuperview()
            let height = UIDevice().ts.isIPhoneX ? 88 : 64
            make.height.equalTo(height)
        }
        
        bottomToolBar.snp.makeConstraints { (make) in
            make.left.bottom.right.equalToSuperview()
            let height = UIDevice().ts.isIPhoneX ? 69 : 49
            make.height.equalTo(height)
        }
    }
    
    func setContentOffset(idx: Int) {
        browser.setContentOffset(CGPoint(x: CGFloat(currentImageIndex) * view.bounds.width, y: 0), animated: false)
    }
    
    // MARK: - Navigation Bar
    
    func navigationBarGobackAction() {
        delegate?.updateImgSelectIndexs(selectedImageIndexs)
        dismiss(animated: true, completion: nil)
    }
    
    /// 导航栏选择按钮事件
    func navigationBarSelectStateChange() {
        if selectedImageIndexs.contains(currentImageIndex) {
            if let i = selectedImageIndexs.index(of: currentImageIndex) {
                selectedImageIndexs.remove(at: i)
            }
            
        } else {
            if selectedImageIndexs.count == MTSPhotoAlbum.default.imgLimitCount {
                //Error
                let alert = UIAlertAction(title: "ok", style: .cancel, handler: nil)
                let numStr = String(format: "%i", MTSPhotoAlbum.default.imgLimitCount)
                let msg = "MTSPhotoAlbum_PicLimitTitle".MTSPhotoAlbumLocalizedString() + numStr + "MTSPhotoAlbum_PicLimitTitleAddition".MTSPhotoAlbumLocalizedString()
                let alertVC = UIAlertController(title: nil, message: msg, preferredStyle: .alert)
                alertVC.addAction(alert)
                present(alertVC, animated: true, completion: nil)
                return
            } else {
                selectedImageIndexs.append(currentImageIndex)
            }
        }
        
        navigationBar.setSelectState(selectedImageIndexs.contains(currentImageIndex))
        configureToolBar()
    }
    
    /// 配置导航栏选择按钮状态
    func configureNavigationBar() {
        
        let ret = selectedImageIndexs.contains(currentImageIndex)
        print(ret)
        navigationBar.setSelectState(ret)
    }
    
    // MARK: - Bottom Tool Bar
    
    /// 配置底部工具栏按钮状态
    func configureToolBar() {
        bottomToolBar.configureDoneState(selectedImageIndexs.count > 0)
        bottomToolBar.configureSelectCount(selectedImageIndexs.count)
    }
    
    /// 控制隐藏显示工具栏
    func changeToolBarHidden() {
        isHiddenToolBar = !isHiddenToolBar
        UIView.animate(withDuration: 0.5) {
            self.navigationBar.alpha = self.isHiddenToolBar ? 0 : 1
            self.bottomToolBar.alpha = self.isHiddenToolBar ? 0 : 1
            
        }
    }
    
    /// 完成按钮
    private func toolBarDoneAction() {
        
        uploadImgs.removeAll()
        for idx in selectedImageIndexs {
            let M = previewImages[idx]
            imageManager.requestImage(for: M.asset!, targetSize: PHImageManagerMaximumSize, contentMode: .default, options: nil) { (img, info) in
                if img != nil {
                    self.uploadImgs.append(img!)
                    self.checkFinishImgDown()
                }
            }
        }
    }
    
    private func checkFinishImgDown() {
        if uploadImgs.count == selectedImageIndexs.count {
            MTSPhotoAlbum.default.electedImgs?(uploadImgs)
            dismiss(animated: false) {
                self.dismissAction?()
            }
        }
    }
    
    
    // MARK: - PanGesture CallBack
    
    func imgPanGestureStartChange() {
        UIView.animate(withDuration: 0.5) {
            self.navigationBar.alpha = 0
            self.bottomToolBar.alpha = 0
        }
    }
    
    func imgPanGestureEndChange(close_state: Bool) {
        if !close_state && !isHiddenToolBar {
            UIView.animate(withDuration: 0.5) {
                self.navigationBar.alpha = 1
                self.bottomToolBar.alpha = 1
            }
            
        }
    }
    
}

// MARK: - UICollectionViewDelegate

extension MTSPhotoBrowserViewController: UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return previewImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell: MTSPhotoBrowserCollectionCell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionCellID, for: indexPath) as! MTSPhotoBrowserCollectionCell
        
        cell.tapEvent = { [weak self] in
            if let ws = self {
                ws.changeToolBarHidden()
            }
        }
        
        cell.startGestureChange = { [weak self] in
            if let ws = self {
                ws.imgPanGestureStartChange()
            }
        }
        
        cell.endGestureChange = { [weak self] (closeState) in
            if let ws = self {
                ws.imgPanGestureEndChange(close_state: closeState)
            }
        }
        
        
        let value = previewImages[indexPath.row]
        cell.setPHAsset(value.asset!)
        cell.listCellF = value.previewOriginFrame
        cell.delegate = self
        return cell
    }
    
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let pageIdx = scrollView.contentOffset.x / UIScreen.main.bounds.size.width
        currentImageIndex = Int(pageIdx)
        configureNavigationBar()

    }
    
}

// MARK: - MTSPhotoBrowserCollectionCellDelegate

extension MTSPhotoBrowserViewController: MTSPhotoBrowserCollectionCellDelegate {
    
    func backgroundAlpha(alpha: CGFloat) {
        browser.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: alpha)
    }
    
    
    func hiddenAction(cell: MTSPhotoBrowserCollectionCell) {
        
        // 关闭时同步选择图片索引内容
        delegate?.updateImgSelectIndexs(selectedImageIndexs)
        
        UIView.animate(withDuration: 0.5, animations: {
            self.browser.backgroundColor = .clear
            if cell.listCellF != nil {
                cell.imageV.frame = cell.listCellF!
            } else {
                cell.imageV.frame = CGRect(x: UIScreen.main.bounds.width / 2.0 - 50, y: UIScreen.main.bounds.height - 100, width: 100, height: 100)
                cell.imageV.alpha = 0
            }
            
        }) { (ret) in
            self.dismiss(animated: false, completion: nil)
        }
        
    }
}


// MARK: - Navigation Bar

class MTSPhotoBrowserNavigationBar: UIView {
    
    private var gobackBtn = UIButton()
    private var selectBtn = UIButton()
    private let unselectImg: UIImage? = UIImage(named: MTSPhotoAlbum.default.imgUnselectName, in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil)
    private let selectImg: UIImage? = UIImage.init(named: MTSPhotoAlbum.default.imgSelectName, in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil)
    /// 返回按钮事件
    var gobackAction: (() -> Void)?
    
    /// 选择按钮事件
    var selectAction: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = "0x353336".ts.color()
        
        gobackBtn.setImage(UIImage(named: "photo_left_back", in: Bundle.MTSPhotoAlbumBundle(), compatibleWith: nil), for: .normal)
        gobackBtn.addTarget(self, action: #selector(goBackEvent), for: .touchUpInside)
        selectBtn.addTarget(self, action: #selector(selectEvent), for: .touchUpInside)
        
        addSubview(gobackBtn)
        addSubview(selectBtn)
        
        
        gobackBtn.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10)
            make.width.height.equalTo(30)
            make.bottom.equalToSuperview().offset(-7)
        }
        
        selectBtn.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-10)
            make.bottom.width.height.equalTo(gobackBtn)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 设置选择状态
    func setSelectState(_ state: Bool) {
        selectBtn.setImage(state ? selectImg : unselectImg, for: .normal)
    }
    
    @objc func goBackEvent() {
        gobackAction?()
    }
    
    @objc func selectEvent() {
        selectAction?()
    }
}

// MARK: - Tool Bar

class MTSPhotoBrowserToolBar: UIView {
    
    private var doneBtn = UIButton()
    private var selectCountLbl = UILabel()
    var toolBarDoneExecute: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = "0x353336".ts.color()
        
        doneBtn.setTitleColor(.white, for: .normal)
        doneBtn.titleLabel?.font = 13.ts.font()
        doneBtn.clipsToBounds = true
        doneBtn.layer.cornerRadius = 4.ts.scale()
        doneBtn.addTarget(self, action: #selector(doneClicked), for: .touchUpInside)
        
        doneBtn.setTitle("MTSPhotoAlbum_done".MTSPhotoAlbumLocalizedString(), for: .normal)
        doneBtn.backgroundColor = .lightGray
        
        
        selectCountLbl.textColor = .white
        selectCountLbl.font = 16.ts.font()
        selectCountLbl.textAlignment = .center
        selectCountLbl.backgroundColor = MTSPhotoAlbum.default.doneButtonEnableColor
        selectCountLbl.layer.cornerRadius = 15.ts.scale()
        selectCountLbl.clipsToBounds = true
        selectCountLbl.text = "0"
        
        addSubview(doneBtn)
        addSubview(selectCountLbl)
        
        selectCountLbl.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(20.ts.scale())
            make.top.equalTo(doneBtn)
            make.width.height.equalTo(30.ts.scale())
        }
        
        doneBtn.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(9.ts.scale())
            make.right.equalToSuperview().offset(-10.ts.scale())
            make.width.equalTo(60.ts.scale())
            make.height.equalTo(30.ts.scale())
        }
        
    }
    
    func configureDoneState(_ state: Bool) {
        doneBtn.isEnabled = state
        doneBtn.backgroundColor = state ? MTSPhotoAlbum.default.doneButtonEnableColor : .lightGray
    }
    
    func configureSelectCount(_ count: Int) {
        let str = String(format: "%i", count)
        selectCountLbl.text = str
    }
    
    @objc func doneClicked() {
        toolBarDoneExecute?()
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension UIView {
    
    /**
     Get the view's screen shot, this function may be called from any thread of your app.
     
     - returns: The screen shot's image.
     */
    func MTS_ScreenShot() -> UIImage? {
        
        guard frame.size.height > 0 && frame.size.width > 0 else {
            
            return nil
        }
        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
}


