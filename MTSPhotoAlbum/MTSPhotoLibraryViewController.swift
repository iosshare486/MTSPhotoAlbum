//
//  MTSPhotoLibraryViewController.swift
//  MJSports
//
//  Created by 彩球 on 2018/7/11.
//  Copyright © 2018年 caiqr. All rights reserved.
//

import UIKit
import Photos
import SnapKit


class MTSAlbumItem {
    var title: String?
    var fetchResult: PHFetchResult<AnyObject>!
    
    init(title:String?,fetchResult:PHFetchResult<AnyObject>){
        self.title = title
        self.fetchResult = fetchResult
    }
}

class MTSPhotoLibraryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    private var items = [MTSAlbumItem]()
    private var photoTableView = UITableView(frame: .zero, style: .plain)
    private var cancelBtn = UIButton()
    
    private var isLoaded: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.navigationBar.isTranslucent = false
        
        photoTableView.delegate = self
        photoTableView.dataSource = self
        photoTableView.separatorStyle = .none
        
        photoTableView.rowHeight = UITableViewAutomaticDimension
        photoTableView.estimatedRowHeight = UITableViewAutomaticDimension
        
        view.addSubview(photoTableView)
        
        photoTableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        cancelBtn.setTitle("MTSPhotoAlbum_cancel".MTSPhotoAlbumLocalizedString(), for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15.ts.scale())
        cancelBtn.setTitleColor("0x6".ts.color(), for: .normal)
        cancelBtn.addTarget(self, action: #selector(closePhotolibrary), for: .touchUpInside)
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: cancelBtn)
        
        fetchAllSystemAblum()
        // Do any additional setup after loading the view.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        fetchAllSystemAblum()
    }
    
    @objc private func closePhotolibrary() {
        dismiss(animated: true, completion: nil)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: MTSPhotoLibraryCell? = tableView.dequeueReusableCell(withIdentifier: "MTSPhotoLibraryCellId") as? MTSPhotoLibraryCell
        if cell == nil {
            cell = MTSPhotoLibraryCell(style: .default, reuseIdentifier: "MTSPhotoLibraryCellId")
        }
        
        let value = items[indexPath.row]
        if value.fetchResult.count > 0 {
            let asset = value.fetchResult.firstObject as! PHAsset
            let targetSize = CGSize(width: 60.ts.scale(), height: 60.ts.scale())
            PHCachingImageManager().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: nil) { (img, info) in
                cell!.imgV.image = img
            }
        }
        let numStr = String(format: "%i", value.fetchResult.count)
        if let title = value.title {
            cell!.photoTitleLbl.text = "\(title) (\(numStr))"
        }
        
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let value = items[indexPath.row]
        let vc = MTSPhotoPreviewViewController()
        vc.photoAlbrum = value.fetchResult
        vc.photoTitle = value.title
        navigationController?.pushViewController(vc, animated: true)
        
    }
    
    func fetchAllSystemAblum() {
        
        if !isLoaded {
            isLoaded = true
            items.append(contentsOf: MTSPhotoAlbum.default.fetchAllPhotoAlbum())
            photoTableView.reloadData()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

class MTSPhotoLibraryCell: UITableViewCell {
    var imgV = UIImageView()
    var photoTitleLbl = UILabel()
    var line = UIView()
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        accessoryType = .disclosureIndicator
        
        photoTitleLbl.font = 15.ts.font()
        imgV.contentMode = .scaleAspectFill
        imgV.clipsToBounds = true
        
        line.backgroundColor = "0xF2F4F6".ts.color()
        
        contentView.addSubview(imgV)
        contentView.addSubview(photoTitleLbl)
        contentView.addSubview(line)
        
        imgV.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(10.ts.scale())
            make.top.equalToSuperview().offset(5.ts.scale())
            make.bottom.equalToSuperview().offset(-5.ts.scale())
            make.height.equalTo(60.ts.scale())
            make.width.equalTo(imgV.snp.height)
        }
        
        photoTitleLbl.snp.makeConstraints { (make) in
            make.left.equalTo(imgV.snp.right).offset(20.ts.scale())
            make.top.right.bottom.equalToSuperview()
        }
        
        line.snp.makeConstraints { (make) in
            make.bottom.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    
    
    
}

