//
//  CountryPicker.swift
//  CountryPicker
//
//  Created by Ibrahim, Mustafa on 1/24/16.
//  Copyright © 2016 Mustafa Ibrahim. All rights reserved.
//

import UIKit

struct Section {

    var countries: [Country] = []

    mutating func addCountry(_ country: Country) {
        countries.append(country)
    }
}

@objc public protocol CountryPickerDelegate: AnyObject {

    @objc optional func countryPicker(_ picker: CountryPicker,
                                      didSelectCountryWithName name: String,
                                      code: String)

    func countryPicker(_ picker: CountryPicker,
                       didSelectCountryWithName name: String,
                       code: String,
                       dialCode: String)
}

open class CountryPicker: UITableViewController {

    fileprivate lazy var CallingCodes = { () -> [[String: String]] in
        let resourceBundle = Bundle(for: CountryPicker.classForCoder())
        guard let path = resourceBundle.path(forResource: "CallingCodes", ofType: "plist") else { return [] }
        return NSArray(contentsOfFile: path) as! [[String: String]]
    }()
    fileprivate let locale = Locale.current as NSLocale
    fileprivate var searchController: UISearchController!
    fileprivate var filteredList = [Country]()
    fileprivate var unsortedCountries : [Country] {
        var unsortedCountries = [Country]()

        for countryCode in countriesCodes {
            guard let displayName = locale.displayName(forKey: .countryCode, value: countryCode) else {
                print("[CountryPicker] Error: Invalid country code \(countryCode)")
                continue
            }

            let countryData = CallingCodes.first { $0["code"] == countryCode }
            let country: Country

            if let dialCode = countryData?["dial_code"] {
                country = Country(name: displayName, code: countryCode, dialCode: dialCode)
            } else {
                country = Country(name: displayName, code: countryCode)
            }
            unsortedCountries.append(country)
        }

        return unsortedCountries
    }

    fileprivate var _sections: [Section]?
    fileprivate var sections: [Section] {
        if let cached = _sections {
            return cached
        }

        let countries: [Country] = unsortedCountries.map { country in
            let country = Country(name: country.name, code: country.code, dialCode: country.dialCode)
            country.section = collation.section(for: country, collationStringSelector: #selector(getter: Country.name))
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

        // Sort each section
        for section in sections {
            var s = section
            s.countries = collation.sortedArray(from: section.countries, collationStringSelector: #selector(getter: Country.name)) as! [Country]
        }

        // Adds current location
        var countryCode = locale.object(forKey: .countryCode) as? String ?? defaultCountryCode
        if forceDefaultCountryCode {
            countryCode = defaultCountryCode
        }

        sections.insert(Section(), at: 0)

        let displayName = locale.displayName(forKey: .countryCode, value: countryCode)
        let callingCode = CallingCodes.first(where: { $0["code"] == countryCode })?["dial_code"]
        let country: Country
        if let displayName, countriesCodes.contains(countryCode) {
            if let callingCode {
                country = Country(name: displayName, code: countryCode, dialCode: callingCode)
            } else {
                country = Country(name: displayName, code: countryCode)
            }

            country.section = 0
            sections[0].addCountry(country)
        }

        _sections = sections

        return _sections!
    }

    fileprivate let collation = UILocalizedIndexedCollation.current() as UILocalizedIndexedCollation

    open weak var delegate: CountryPickerDelegate?

    /// Closure which returns country name and ISO code
    open var didSelectCountryClosure: ((String, String) -> ())?

    /// Closure which returns country name, ISO code, calling codes
    open var didSelectCountryWithCallingCodeClosure: ((String, String, String) -> ())?

    /// Countries to show, defaults to `Locale.isoRegionCodes`
    open var countriesCodes: [String] = Locale.isoRegionCodes {
        didSet {
            // Clear sections cache
            _sections = nil
        }
    }

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

    /// The color of the separator between sections. Defaults to gray
    open var separatorColor = UIColor.gray

    /// The tint color of the close icon in presented pickers. Defaults to black
    open var closeButtonTintColor = UIColor.black

    /// The font of the country name list
    open var font = UIFont.systemFont(ofSize: 15)

    /// The font of the flags shown. Defaults to 35pt
    open var fontFlag = UIFont.systemFont(ofSize: 35)

    /// Flag to indicate if the navigation bar should be hidden when search becomes active. Defaults to true
    open var hidesNavigationBarWhenPresentingSearch = true

    /// The background color of the searchbar. Defaults to `nil`
    open var searchBarBackgroundColor: UIColor? = nil

    /// The style of the searchbar. Defaults to `.default`
    open var searchBarStyle = UISearchBar.Style.default

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

        tableView.backgroundView = UIView() // https://stackoverflow.com/a/36270436/1327557
        tableView.sectionIndexColor = alphabetScrollBarTintColor
        tableView.sectionIndexBackgroundColor = alphabetScrollBarBackgroundColor
        tableView.rowHeight = max(font.lineHeight, fontFlag.lineHeight)
        tableView.sectionFooterHeight = 0
        tableView.separatorColor = separatorColor
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationItem.title = pickerTitle
    }

    // MARK: Methods

    @objc private func dismissView() {
        dismiss(animated: true, completion: nil)
    }

    fileprivate func createSearchBar() {
        if tableView.tableHeaderView == nil {
            searchController = UISearchController(searchResultsController: nil)
            searchController.searchResultsUpdater = self
            searchController.hidesNavigationBarDuringPresentation = hidesNavigationBarWhenPresentingSearch
            searchController.searchBar.searchBarStyle = searchBarStyle
            searchController.searchBar.barTintColor = searchBarBackgroundColor
            tableView.tableHeaderView = searchController.searchBar
        }
    }

    fileprivate func filter(_ searchText: String) -> [Country] {
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

    fileprivate func getCountry(_ code: String) -> Country? {
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

extension CountryPicker {

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

        let country: Country!
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
        guard !sections[section].countries.isEmpty else {
            return nil
        }

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

    override open func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if sections[section].countries.isEmpty {
            return 0 // Hide header
        }
        return UITableView.automaticDimension
    }

    open override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if sections[section].countries.isEmpty {
            return nil // Hide header
        }
        return super.tableView(tableView, viewForHeaderInSection: section)
    }

    override open func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        collation.sectionIndexTitles
    }

    override open func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        collation.section(forSectionIndexTitle: index+1)
    }
}

// MARK: - Table view delegate

extension CountryPicker {

    override open func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let country: Country!
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

extension CountryPicker: UISearchResultsUpdating {

    public func updateSearchResults(for searchController: UISearchController) {
        _ = filter(searchController.searchBar.text!)

        if !hidesNavigationBarWhenPresentingSearch {
            searchController.searchBar.showsCancelButton = false
        }
        tableView.reloadData()
    }
}
