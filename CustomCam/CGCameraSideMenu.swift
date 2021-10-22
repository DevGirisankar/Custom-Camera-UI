//
//  CGCameraSideMenu.swift
//  CustomCam
//
//  Created by Giri on 22/10/21.
//

import Foundation
import UIKit

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sideMenuOptions.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sideMenuTableviewCell", for: indexPath) as! sideMenuTableviewCell
        cell.iconView.image = UIImage.init(named: "\(sideMenuOptions[indexPath.row].rawValue)")
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        print(#function)
    }
    func setupSideMenu() {
        sideMenu.maxHeight = self.view.bounds.height
        sideMenu.delegate = self
        sideMenu.dataSource = self
        sideMenu.reloadData()
    }
    func recalculateSideMenuHeight() {
        sideMenu.reloadData()
    }
}
