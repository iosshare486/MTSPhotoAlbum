//
//  MTSPhotoBrowserCollectionCell.swift
//  MJSports
//
//  Created by 彩球 on 2018/7/13.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit
import Photos
import SnapKit

protocol MTSPhotoBrowserCollectionCellDelegate {
    
    func backgroundAlpha(alpha: CGFloat)
    func hiddenAction(cell: MTSPhotoBrowserCollectionCell)
}

class MTSPhotoBrowserCollectionCell: UICollectionViewCell {
    
    let ImageW = UIScreen.main.bounds.size.width - 10
    
    
    fileprivate lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.delegate = self
        sv.backgroundColor = .clear
        sv.maximumZoomScale = 2
        sv.minimumZoomScale = 1
        return sv
    }()
    
    lazy var imageV: UIImageView = {
        let v = UIImageView()
        self.scrollView.addSubview(v)
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.isUserInteractionEnabled = true
        return v
    }()
    
    var delegate: MTSPhotoBrowserCollectionCellDelegate?
    
    var longPressEvent: ((UIImage) -> Void)?
    var tapEvent: (() -> Void)?
    
    /// 开始移动
    var startGestureChange: (() -> Void)?
    /// 结束移动 参数-是否关闭操作
    var endGestureChange: ((Bool) -> Void)?
    
    var listCellF: CGRect?
    var isFirstLoad: Bool = false
    
    fileprivate var imgOriginF: CGRect? //在中心时候的坐标
    fileprivate var imgOriginCenter: CGPoint?
    fileprivate var moveImgFirstPoint: CGPoint? //记录第一次移动图片位置
    
    fileprivate var firstTouchPoint: CGPoint? // 记录刚触碰第一次时候的点
    
    fileprivate var panGes: UIPanGestureRecognizer!
    fileprivate var tapSingle: UITapGestureRecognizer!
    fileprivate var tapDouble: UITapGestureRecognizer!
    
    
    
    // 控制时间
    fileprivate var panStartTime: Date?
    fileprivate var panEndTime: Date?
    
    fileprivate var panPoints = [CGFloat]()
    fileprivate var imgCacheManager: PHCachingImageManager!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imgCacheManager = PHCachingImageManager()
        contentView.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        contentView.addSubview(scrollView)
        initGesture()
        
        
    }
    
    
    
    private func initGesture() {
        panGes = UIPanGestureRecognizer(target: self, action: #selector(imageViewPressAction(ges:)))
        panGes.delegate = self
        scrollView.addGestureRecognizer(panGes)
        
        tapSingle = UITapGestureRecognizer(target: self, action: #selector(imageViewSingleTapAction(ges:)))
        tapSingle.delegate = self
        tapSingle.numberOfTapsRequired = 1
        scrollView.addGestureRecognizer(tapSingle)
        
        tapDouble = UITapGestureRecognizer(target: self, action: #selector(imageViewDoubleTapAction(ges:)))
        tapDouble.numberOfTapsRequired = 2
        tapSingle.require(toFail: tapDouble)
        scrollView.addGestureRecognizer(tapDouble)
        
//        let long = UILongPressGestureRecognizer(target: self, action: #selector(imageViewLongPressAction(ges:)))
//        imageV.addGestureRecognizer(long)
    }
    
    func setPicImage(_ img: UIImage) {
        imageV.image = img
        updateImageView(img: img)
    }
    
    func setPHAsset(_ asset: PHAsset) {
        
        imgCacheManager.requestImage(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil) { [weak self] (img, info) in
            if let ws = self {
                ws.imageV.image = img
                ws.updateImageView(img: img)
            }
        }
    }
    
    
    private func updateImageView(img: UIImage?) {
        if img == nil {
            return
        }
        imgOriginF = nil
        imgOriginCenter = nil
        moveImgFirstPoint = nil
        firstTouchPoint = nil
        scrollView.zoomScale = 1
        
        
        imageV.image = img
        var imageView_Y: CGFloat = 0.0
        let imageWidth: CGFloat = img!.size.width
        let imageHeight: CGFloat = img!.size.height
        
        
        let fitWidth: CGFloat = ImageW
        let fitHeight: CGFloat = fitWidth * imageHeight / imageWidth
        
        if fitHeight < UIScreen.main.bounds.size.height {
            imageView_Y = (UIScreen.main.bounds.size.height - fitHeight) * 0.5
        }
        
        imgOriginF = CGRect(x: 5.0, y: imageView_Y, width: fitWidth, height: fitHeight)
        
        
        if isFirstLoad && listCellF != nil {
            isFirstLoad = false
            imageV.frame = listCellF!
            UIView.animate(withDuration: 0.3) {
                self.imageV.frame = self.imgOriginF!
                self.imgOriginCenter = self.imageV.center
                self.delegate?.backgroundAlpha(alpha: 1)
            }
            
        } else {
            imageV.frame = imgOriginF!
            imgOriginCenter = imageV.center
        }
        
        scrollView.contentSize = CGSize(width: fitWidth, height: fitHeight)
        
    }
    
    
    /// 隐藏
    private func hiddenAction() {
        
        self.delegate?.hiddenAction(cell: self)
    }
    
    /// 拖拽
    @objc func imageViewPressAction(ges: UIPanGestureRecognizer) {
        
        let movePoint = ges.location(in: self.window)
        switch ges.state {
        case .began:
            panPoints.removeAll()
            panStartTime = Date()
            moveImgFirstPoint = ges.location(in: self.window)
            startGestureChange?()
            break
        case .changed:
            
            
            panPoints.append(movePoint.y)
            
            
            let value = movePoint.y - (moveImgFirstPoint?.y)!
            if value < 0 {
                let transhform1 = CGAffineTransform(translationX: movePoint.x - moveImgFirstPoint!.x, y: movePoint.y - moveImgFirstPoint!.y)
                self.imageV.transform = CGAffineTransform(scaleX: 1.0, y: 1.0).concatenating(transhform1)
                self.delegate?.backgroundAlpha(alpha: 1)
            } else {
                let scale = value / (UIScreen.main.bounds.size.height * 2.0 / 3.0)
                let alpha = value / (UIScreen.main.bounds.size.height / 4.0)
                let transhform1 = CGAffineTransform(translationX: movePoint.x - moveImgFirstPoint!.x, y: movePoint.y - moveImgFirstPoint!.y)
                let ss = (1.0 - scale)
                self.imageV.transform = CGAffineTransform(scaleX: ss, y: ss).concatenating(transhform1)
                self.delegate?.backgroundAlpha(alpha: fmax(1.0 - alpha, 0))
            }
            
        case .ended:
            
            var tmpNum: CGFloat = 2000.0
            let lastValue = panPoints.last
            for i in panPoints.reversed() {
                if i < tmpNum {
                    tmpNum = i
                } else {
                    break
                }
            }
            
            if lastValue! - tmpNum > 10.0 && lastValue! > contentView.bounds.size.height / 2.0 {
                hiddenAction()
                endGestureChange?(true)
            } else {
                endGestureChange?(false)
                UIView.animate(withDuration: 0.2) {
                    let transform1 = CGAffineTransform(translationX: 0, y: 0)
                    self.imageV.transform = CGAffineTransform(scaleX: 1, y: 1).concatenating(transform1)
                    self.delegate?.backgroundAlpha(alpha: 1)
                }
            }

        default:
            break
        }
        
    }
    /// 单击
    @objc func imageViewSingleTapAction(ges: UIPanGestureRecognizer) {
        tapEvent?()
    }
    
    /// 双击
    @objc func imageViewDoubleTapAction(ges: UIPanGestureRecognizer) {
        scrollView.setZoomScale(((scrollView.zoomScale == 1) ? 2 : 1), animated: true)
    }
    
    /// 长按
    @objc func imageViewLongPressAction(ges: UILongPressGestureRecognizer) {
        if ges.state == .began {
            if let img = imageV.image {
                longPressEvent?(img)
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        scrollView.frame = CGRect(origin: CGPoint.zero, size: contentView.bounds.size)
        
    }
    
    
}
// MARK: - UIGestureRecognizerDelegate
extension MTSPhotoBrowserCollectionCell: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == panGes {
            firstTouchPoint = touch.location(in: self.window)
        }
        return true
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if firstTouchPoint == nil {
            return true
        }
        
        let touchPoint = gestureRecognizer.location(in: self.window)
        let dirTop = firstTouchPoint!.y - touchPoint.y
        if dirTop > -10 && dirTop < 10 {
            return false
        }
        
        let dirLieft = firstTouchPoint!.x - touchPoint.x
        if dirLieft > -10 && dirLieft < 10 && imageV.frame.size.height > UIScreen.main.bounds.size.height {
            return false
        }
        
        return true
    }
}

// MARK: - UIScrollViewDelegate
extension MTSPhotoBrowserCollectionCell: UIScrollViewDelegate {
    
    /// 缩放图片的时候将图片放在中间
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = scrollView.bounds.size.width > scrollView.contentSize.width ? (scrollView.bounds.size.width - scrollView.contentSize.width) * 0.5 : 0.0
        let offsetY = scrollView.bounds.size.height > scrollView.contentSize.height ? (scrollView.bounds.size.height - scrollView.contentSize.height) * 0.5 : 0.0
        imageV.center = CGPoint(x: scrollView.contentSize.width * 0.5 + offsetX, y: scrollView.contentSize.height * 0.5 + offsetY)
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageV
    }
    
    
}
