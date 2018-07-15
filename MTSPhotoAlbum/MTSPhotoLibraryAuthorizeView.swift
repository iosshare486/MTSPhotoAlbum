//
//  MTSPhotoLibraryAuthorizeView.swift
//  MJSports
//
//  Created by 彩球 on 2018/7/12.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit

class MTSPhotoLibraryAuthorizeView: UIView {

    
    var message: UILabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        message.textAlignment = .center
        message.numberOfLines = 0
        addSubview(message)
        
        message.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.height.equalTo(100.ts.scale())
            make.top.equalToSuperview().offset(130.ts.scale())
        }
        
        message.text = MTSPhotoAlbum.default.photoAuthorizeDeniedMessage
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
