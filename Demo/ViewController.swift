//
//  ViewController.swift
//  CountryPicker
//
//  Created by Amila on 21/4/17.
//  Copyright © 2017 Amila Diman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var countryNameLabel: UILabel!
    @IBOutlet weak var countryCodeLabel: UILabel!
    @IBOutlet weak var countryCallingCodeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func openPickerAction(_ sender: AnyObject) {
        
        let picker = CountryPicker(style: .grouped)
        picker.delegate = self

        // Display calling codes
        picker.showCallingCodes = true

        // or closure
        picker.didSelectCountryClosure = { name, code in
            _ = picker.navigationController?.popToRootViewController(animated: true)
            print(code)
        }

        // Use this below code to present the picker
        let pickerNavigationController = UINavigationController(rootViewController: picker)
        self.present(pickerNavigationController, animated: true, completion: nil)
    }
}

extension ViewController: @MainActor CountryPickerDelegate {

    func countryPicker(_ picker: CountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        _ = picker.navigationController?.popToRootViewController(animated: true)
        self.dismiss(animated: true, completion: nil)
        countryNameLabel.text = name
        countryCodeLabel.text = code
        countryCallingCodeLabel.text = dialCode
        
        _ =  picker.getFlag(countryCode: code)
        _ =  picker.getCountryName(countryCode: code)
        _ =  picker.getDialCode(countryCode: code)
    }
}
