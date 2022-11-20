//
//  MenuVC.swift
//  Scanner 3D
//
//  Created by Vladislav Mikheenko on 20.11.2022.
//

import UIKit

class MenuVC: UIViewController {

    //MARK: UI
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.delegate = self
            collectionView.dataSource = self
            collectionView.register(UINib(nibName: "MenuCell",bundle: nil), forCellWithReuseIdentifier: "MenuCell")
            collectionView.backgroundColor = .gray
            
        }
    }
    
    //MARK: properties
    private var namesArray = [String]()
    private let dataManager = DataStorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let wrapArray = dataManager.getObjScens() {
            namesArray = wrapArray
            collectionView.reloadData()
        }
    }
    
}

extension MenuVC: UICollectionViewDelegate {}

extension MenuVC: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return namesArray.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MenuCell", for: indexPath) as! MenuCell
        cell.mainView.backgroundColor = .lightGray
        cell.mainView.layer.cornerRadius = 10
        cell.label.text = ""
        cell.label.text = namesArray[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let vc = SceneVC(nibName: "SceneVC", bundle: nil)
        vc.modelName = namesArray[indexPath.row]
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
}
