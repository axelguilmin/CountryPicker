//
//  ADCountryPicker.swift
//  ADCountryPicker
//
//  Created by Ibrahim, Mustafa on 1/24/16.
//  Copyright © 2016 Mustafa Ibrahim. All rights reserved.
//

import UIKit

struct Section {

    var countries: [ADCountry] = []

    mutating func addCountry(_ country: ADCountry) {
        countries.append(country)
    }
}

@objc public protocol ADCountryPickerDelegate: class {

    @objc optional func countryPicker(_ picker: ADCountryPicker,
                                      didSelectCountryWithName name: String,
                                      code: String)

    func countryPicker(_ picker: ADCountryPicker,
                       didSelectCountryWithName name: String,
                       code: String,
                       dialCode: String)
}

open class ADCountryPicker: UITableViewController {

    fileprivate lazy var CallingCodes = { () -> [[String: String]] in
        let resourceBundle = Bundle(for: ADCountryPicker.classForCoder())
        guard let path = resourceBundle.path(forResource: "CallingCodes", ofType: "plist") else { return [] }
        return NSArray(contentsOfFile: path) as! [[String: String]]
    }()
    fileprivate var searchController: UISearchController!
    fileprivate var filteredList = [ADCountry]()
    fileprivate var unsortedCountries : [ADCountry] {
        let locale = Locale.current as NSLocale
        var unsortedCountries = [ADCountry]()

        for countryCode in countriesCodes {
            guard let displayName = locale.displayName(forKey: .countryCode, value: countryCode) else {
                print("[CountryPicker] Error: Invalid country code \(countryCode)")
                continue
            }

            let countryData = CallingCodes.first { $0["code"] == countryCode }
            let country: ADCountry

            if let dialCode = countryData?["dial_code"] {
                country = ADCountry(name: displayName, code: countryCode, dialCode: dialCode)
            } else {
                country = ADCountry(name: displayName, code: countryCode)
            }
            unsortedCountries.append(country)
        }

        return unsortedCountries
    }

    fileprivate var _sections: [Section]?
    fileprivate var sections: [Section] {

        if _sections != nil {
            return _sections!
        }

        let countries: [ADCountry] = unsortedCountries.map { country in
            let country = ADCountry(name: country.name, code: country.code, dialCode: country.dialCode)
            country.section = collation.section(for: country, collationStringSelector: #selector(getter: ADCountry.name))
            return country
        }

        // create empty sections
        var sections = [Section]()
        for _ in 0..<collation.sectionIndexTitles.count {
            sections.append(Section())
        }

        // Put each country in a section
        for country in countries {
            sections[country.section!].addCountry(country)
        }

        // Remove empty sections
        sections.removeAll { $0.countries.isEmpty }

        // Sort each section
        for section in sections {
            var s = section
            s.countries = collation.sortedArray(from: section.countries, collationStringSelector: #selector(getter: ADCountry.name)) as! [ADCountry]
        }

        // Adds current location
        var countryCode = (Locale.current as NSLocale).object(forKey: .countryCode) as? String ?? defaultCountryCode
        if forceDefaultCountryCode {
            countryCode = defaultCountryCode
        }

        sections.insert(Section(), at: 0)
        let locale = Locale.current
        let displayName = (locale as NSLocale).displayName(forKey: NSLocale.Key.countryCode, value: countryCode)
        let countryData = CallingCodes.filter { $0["code"] == countryCode }
        let country: ADCountry

        if countryData.count > 0, let dialCode = countryData[0]["dial_code"] {
            country = ADCountry(name: displayName!, code: countryCode, dialCode: dialCode)
        } else {
            country = ADCountry(name: displayName!, code: countryCode)
        }
        country.section = 0
        sections[0].addCountry(country)

        _sections = sections

        return _sections!
    }

    fileprivate let collation = UILocalizedIndexedCollation.current() as UILocalizedIndexedCollation

    open weak var delegate: ADCountryPickerDelegate?

    /// Closure which returns country name and ISO code
    open var didSelectCountryClosure: ((String, String) -> ())?

    /// Closure which returns country name, ISO code, calling codes
    open var didSelectCountryWithCallingCodeClosure: ((String, String, String) -> ())?

    /// Countries to show, defaults to `Locale.isoRegionCodes`
    open var countriesCodes: [String] = Locale.isoRegionCodes

    /// Flag to indicate if calling codes should be shown next to the country name. Defaults to false.
    open var showCallingCodes = false

    /// Flag to indicate whether country flags should be shown on the picker. Defaults to true
    open var showFlags = true

    /// The nav bar title to show on picker view
    open var pickerTitle = "Select a Country"

    /// The default current location, if region cannot be determined. Defaults to US
    open var defaultCountryCode = "US"

    /// Flag to indicate whether the defaultCountryCode should be used even if region can be deteremined. Defaults to false
    open var forceDefaultCountryCode = false

    /// The text color of the alphabet scrollbar. Defaults to black
    open var alphabetScrollBarTintColor = UIColor.black

    /// The background color of the alphabet scrollar. Default to clear color
    open var alphabetScrollBarBackgroundColor = UIColor.clear

    /// The tint color of the close icon in presented pickers. Defaults to black
    open var closeButtonTintColor = UIColor.black

    /// The font of the country name list
    open var font = UIFont.systemFont(ofSize: 15)

    /// The font of the flags shown. Defaults to 35pt
    open var fontFlag = UIFont.systemFont(ofSize: 35)

    /// Flag to indicate if the navigation bar should be hidden when search becomes active. Defaults to true
    open var hidesNavigationBarWhenPresentingSearch = true

    /// The background color of the searchbar. Defaults to lightGray
    open var searchBarBackgroundColor = UIColor.lightGray

    /// The SF symbol image name of the close icon. Defaults to `xmark`
    open var closeIconImageName = "xmark"

    convenience public init(completionHandler: @escaping ((String, String) -> ())) {
        self.init()
        self.didSelectCountryClosure = completionHandler
    }

    override open func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = pickerTitle

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        createSearchBar()
        tableView.reloadData()

        definesPresentationContext = true

        if presentingViewController != nil {
            let image = UIImage(systemName: closeIconImageName)
            let closeButton = UIBarButtonItem(image: image,
                                              style: .plain,
                                              target: self,
                                              action: #selector(dismissView))

            closeButton.tintColor = closeButtonTintColor
            navigationItem.leftBarButtonItem = nil
            navigationItem.leftBarButtonItem = closeButton
        }

        tableView.sectionIndexColor = alphabetScrollBarTintColor
        tableView.sectionIndexBackgroundColor = alphabetScrollBarBackgroundColor
        tableView.rowHeight = max(font.lineHeight, fontFlag.lineHeight)
        tableView.separatorColor = UIColor(red: (222)/(255.0),
                                           green: (222)/(255.0),
                                           blue: (222)/(255.0),
                                           alpha: 1)
    }

    // MARK: Methods

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    fileprivate func createSearchBar() {
        if tableView.tableHeaderView == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.dimsBackgroundDuringPresentation = false
            searchController.hidesNavigationBarDuringPresentation = hidesNavigationBarWhenPresentingSearch
            searchController.searchBar.searchBarStyle = .prominent
            searchController.searchBar.barTintColor = searchBarBackgroundColor
            searchController.searchBar.showsCancelButton = false
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    fileprivate func filter(_ searchText: String) -> [ADCountry] {
        filteredList.removeAll()

        sections.forEach { section in
            section.countries.forEach { country in
                if country.name.count >= searchText.count {
                    let result = country.name.compare(searchText,
                                                      options: [.caseInsensitive, .diacriticInsensitive],
                                                      range: searchText.startIndex ..< searchText.endIndex)
                    if result == .orderedSame {
                        filteredList.append(country)
                    }
                }
            }
        }

        return filteredList
    }

    fileprivate func getCountry(_ code: String) -> ADCountry? {
        unsortedCountries.first {
            let result = $0.code.compare(code,
                                         options: [.caseInsensitive, .diacriticInsensitive],
                                         range: code.startIndex ..< code.endIndex)
            return result == .orderedSame
        }
    }


    // MARK: - Public method

    /// Returns the country flag for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get flag for
    /// - Returns: the emoji for given country code
    public func getFlag(countryCode: String) -> String {
        if getCountry(countryCode) != nil {
            let base: UInt32 = 127397
            var emoji = ""
            for scalar in countryCode.unicodeScalars {
                emoji.unicodeScalars.append(UnicodeScalar(base + scalar.value)!)
            }
            return String(emoji)
        } else {
            assertionFailure("Unknown country code: \(countryCode)")
            return "🏳️"
        }
    }

    /// Returns the country dial code for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get dialing code for
    /// - Returns: the dial code for given country code if it exists
    public func getDialCode(countryCode: String) -> String? {
        getCountry(countryCode)?.dialCode
    }

    /// Returns the country name for the given country code
    ///
    /// - Parameter countryCode: ISO code of country to get dialing code for
    /// - Returns: the country name for given country code if it exists
    public func getCountryName(countryCode: String) -> String? {
        getCountry(countryCode)?.name
    }
}

// MARK: - Table view data source

extension ADCountryPicker {

    override open func numberOfSections(in tableView: UITableView) -> Int {
        if searchController.searchBar.text!.count > 0 {
            return 1
        }
        return sections.count
    }

    override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchController.searchBar.text!.count > 0 {
            return filteredList.count
        }
        return sections[section].countries.count
    }

    override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tempCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell")

        if tempCell == nil {
            tempCell = UITableViewCell(style: .default, reuseIdentifier: "UITableViewCell")
        }

        let cell: UITableViewCell! = tempCell

        let country: ADCountry!
        if searchController.searchBar.text!.count > 0 {
            country = filteredList[(indexPath as NSIndexPath).row]
        } else {
            country = sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]
        }

        cell.textLabel?.font = font

        if showCallingCodes {
            cell.textLabel?.text = country.name + " (" + country.dialCode + ")"
        } else {
            cell.textLabel?.text = country.name
        }

        if showFlags {
            let flag = getFlag(countryCode: country.code) + " "
            let countryName = cell.textLabel?.text ?? ""
            let text = flag + countryName

            let string = NSMutableAttributedString(string: text)
            let rangeFlag = NSRange(text.range(of: flag)!, in: text)
            let rangeCountryName = NSRange(text.range(of: countryName)!, in: text)

            string.beginEditing()
            string.addAttribute(.font, value: font as Any, range: rangeCountryName)
            string.addAttribute(.font, value: fontFlag as Any, range: rangeFlag)
            string.addAttribute(.baselineOffset, value: (fontFlag.xHeight - font.xHeight) * 0.5, range: rangeCountryName)
            string.endEditing()

            cell.textLabel?.attributedText = string
        }

        return cell
    }

    override open func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if !sections[section].countries.isEmpty {
            if searchController.searchBar.text!.count > 0 {
                if let name = filteredList.first?.name {
                    let index = name.index(name.startIndex, offsetBy: 0)
                    return String(describing: name[index])
                }

                return ""
            }

            if section == 0 {
                return "Current Location"
            }

            return collation.sectionTitles[section-1] as String
        }

        return ""
    }

    override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        section == 0 ? 50 : 26
    }

    override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        collation.sectionIndexTitles
    }

    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        collation.section(forSectionIndexTitle: index+1)
    }
}

// MARK: - Table view delegate

extension ADCountryPicker {

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country: ADCountry!
        if searchController.searchBar.text!.count > 0 {
            country = filteredList[(indexPath as NSIndexPath).row]
        } else {
            country = sections[(indexPath as NSIndexPath).section].countries[(indexPath as NSIndexPath).row]
        }
        delegate?.countryPicker?(self, didSelectCountryWithName: country.name, code: country.code)
        delegate?.countryPicker(self, didSelectCountryWithName: country.name, code: country.code, dialCode: country.dialCode)
        didSelectCountryClosure?(country.name, country.code)
        didSelectCountryWithCallingCodeClosure?(country.name, country.code, country.dialCode)
    }
}

// MARK: - UISearchDisplayDelegate

extension ADCountryPicker: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        _ = filter(searchController.searchBar.text!)

        if !hidesNavigationBarWhenPresentingSearch {
            searchController.searchBar.showsCancelButton = false
        }
        tableView.reloadData()
    }
}
