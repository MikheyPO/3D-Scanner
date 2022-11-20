//
//  DataStorageManager.swift
//  Scanner 3D
//
//  Created by Vladislav Mikheenko on 19.11.2022.
//

import Foundation

class DataStorageManager {
    
   private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getObjScens() -> [String]? {
        let docsPath = getDocumentsDirectory()
        
//        let w = try? FileManager.default.contentsOfDirectory(at: docsPath, includingPropertiesForKeys: nil)
//        print("wwww \(w)")
        if let items = try? FileManager.default.contentsOfDirectory(atPath: docsPath.path) {
            var nameArray = [String]()
            
            //FIXME: delete mtl model in FM
            for i in items {
                print("i name \(i)")
                if i.contains(".obj") {
                    nameArray.append(i)
                }
            }
            
            nameArray.sort(by: {$0 > $1})
            
            return nameArray
        }
        
        return nil
    }
    
    //Find file url and check file exist
    func getFileUrl(for name: String) -> URL? {
        let url = getDocumentsDirectory().appendingPathComponent(name, conformingTo: .url)
        print("test 1 \(url)")
        if FileManager.default.fileExists(atPath: url.path) {
            print("test 2 \(url)")
            return url
        }
        return nil
    }
    
}
