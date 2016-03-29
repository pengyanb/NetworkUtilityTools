//
//  UdpListenerCapturedInfoTableViewCell.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 13/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class UdpListenerCapturedInfoTableViewCell: UITableViewCell {

    @IBOutlet weak var leftIcon: UIImageView!
    
    @IBOutlet weak var title: UILabel!
    
    @IBOutlet weak var details: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
