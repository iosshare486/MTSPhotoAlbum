//
//  ViewController.swift
//  MTSPhotoLibraryAlbum
//
//  Created by 彩球 on 2018/7/15.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        MTSPhotoAlbum.default.electedImgs = { (imgs) in
            
        }
        
        
        MTSPhotoAlbum.callPhotoAlbum(launchViewController: self, imageLimit: 2)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

