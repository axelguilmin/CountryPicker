
# CountryPicker

CountryPicker is a country picker controller for iOS13+ with an option to search. The list of countries is based on the ISO 3166 country code standard (http://en.wikipedia.org/wiki/ISO_3166-1). Also and the library includes a set of 250 public domain flag images.

The picker provides:
-   Country Names
-   Country codes - ISO 3166
-   International Dialing Codes
-   Flags using Apple emojis 

## Screenshots

![alt tag](https://github.com/AmilaDiman/ADCountryPicker/blob/master/screen1.png) ![alt tag](https://github.com/AmilaDiman/ADCountryPicker/blob/master/screen2.png) ![alt tag](https://github.com/AmilaDiman/ADCountryPicker/blob/master/screen3.png)
![alt tag](https://github.com/AmilaDiman/ADCountryPicker/blob/master/screen4.png)

*Note: current location is determined from the current region of the iPhone

## Installation

CountryPicker is available through [CocoaPods](http://cocoapods.org), to install it simply add the following line to your Podfile:

    pod 'CountryPicker', :git => 'https://github.com/axelguilmin/CountryPicker.git'
    

Push CountryPicker from UIViewController

```swift

let picker = CountryPicker(style: .grouped)
navigationController?.pushViewController(picker, animated: true)

```
Present CountryPicker from UIViewController

```swift

let picker = CountryPicker()
let pickerNavigationController = UINavigationController(rootViewController: picker)
self.present(pickerNavigationController, animated: true, completion: nil)

```
## CountryPicker properties

```swift

/// delegate
picker.delegate = self

/// Countries to show, defaults to `Locale.isoRegionCodes`
picker.countriesCodes = ["FR", "BE", "DE"]

/// Optionally, set this to display the country calling codes after the names
picker.showCallingCodes = true

/// Flag to indicate whether country flags should be shown on the picker. Defaults to true
picker.showFlags = true
    
/// The nav bar title to show on picker view
picker.pickerTitle = "Select a Country"
    
/// The section title to show for the users current location
picker.currentLocationTitle = "Current Location"
    
/// The default current location, if region cannot be determined. Defaults to US
picker.defaultCountryCode = "US"

/// Flag to indicate whether the defaultCountryCode should be used even if region can be deteremined. Defaults to false
picker.forceDefaultCountryCode = false

/// The text color of the alphabet scrollbar. Defaults to black
picker.alphabetScrollBarTintColor = UIColor.black
    
/// The background color of the alphabet scrollar. Default to clear color
picker.alphabetScrollBarBackgroundColor = UIColor.clear

/// The color of the separator between sections. Defaults to gray
picker.separatorColor = UIColor.gray
    
/// The tint color of the close icon in presented pickers. Defaults to black
picker.closeButtonTintColor = UIColor.black

/// The font of the country name list
picker.font = UIFont.systemFont(ofSize: 15)

/// The font of the flags shown. Defaults to 35pt
picker.fontFlag = UIFont.systemFont(ofSize: 35)

/// Flag to indicate if the navigation bar should be hidden when search becomes active. Defaults to true
picker.hidesNavigationBarWhenPresentingSearch = true

/// The background color of the searchbar. Defaults to `nil`
picker.searchBarBackgroundColor = nil

/// The style of the searchbar. Defaults to `.default`
picker.searchBarStyle = UISearchBar.Style.default

/// The SF symbol image name of the close icon. Defaults to `xmark`
picker.closeIconImageName = "xmark"

```
## CountryPickerDelegate protocol

```swift

func countryPicker(picker: ADCountryPicker, didSelectCountryWithName name: String, code: String) {
        print(code)
}

func countryPicker(picker: ADCountryPicker, didSelectCountryWithName name: String, code: String, dialCode: String) {
        print(dialCode)
}

```

## Closure

```swift

// or closure
picker.didSelectCountryClosure = { name, code in
        print(code)
}

picker.didSelectCountryWithCallingCodeClosure = { name, code, dialCode in
        print(dialCode)
}

```
## Supporting Functions

```swift

/// Returns the country flag for the given country code
///
/// - Parameter countryCode: ISO code of country to get flag for
/// - Returns: the emoji for given country code
let flagEmoji =  picker.getFlag(countryCode: code)


/// Returns the country name for the given country code
///
/// - Parameter countryCode: ISO code of country to get dialing code for
/// - Returns: the country name for given country code if it exists
let countryName =  picker.getCountryName(countryCode: code)


/// Returns the country dial code for the given country code
///
/// - Parameter countryCode: ISO code of country to get dialing code for
/// - Returns: the dial code for given country code if it exists
let dialingCode =  picker.getDialCode(countryCode: code)

```
## Author

Forked from [AmilaDiman](https://github.com/AmilaDiman)/[ADCountryPicker](https://github.com/AmilaDiman/ADCountryPicker)

Notes
============

Designed for iOS 13+.

## License

CountryPicker is available under the MIT license. See the LICENSE file for more info.
