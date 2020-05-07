## [4.0.1](https://github.com/AFNetworking/AFNetworking/releases/tag/4.0.1) (04/19/2020)
Release on Sunday, April 19, 2020. All issues associated with this milestone can be found using this [filter](https://github.com/AFNetworking/AFNetworking/milestone/20?closed=1).

#### Updated
* Project templates and integrations.
  * Implemented by Kaspik in [#4531](https://github.com/AFNetworking/AFNetworking/pull/4531).
* Various CocoaPods podspec settings.
  * Implemented by ElfSundae in [#4528](https://github.com/AFNetworking/AFNetworking/pull/4528), [#4532](https://github.com/AFNetworking/AFNetworking/pull/4532), and [#4533](https://github.com/AFNetworking/AFNetworking/pull/4533).

#### Fixed
* Crash during authentication delegate method.
  * Implemented by Kaspik, ElfSundae, and jshier in [#4542](https://github.com/AFNetworking/AFNetworking/pull/4542), [#4552](https://github.com/AFNetworking/AFNetworking/pull/4552), and [#4553](https://github.com/AFNetworking/AFNetworking/pull/4553).
* SPM integration.
  * Implemented by jshier in [#4554](https://github.com/AFNetworking/AFNetworking/pull/4554).
* Improper update instead of replacement of header values.
  * Implemented by ElfSundae in [#4550](https://github.com/AFNetworking/AFNetworking/pull/4550).
* Nullability of some methods.
  * Implemented by ElfSundae in [#4551](https://github.com/AFNetworking/AFNetworking/pull/4551).
* Typos in CHANGELOG.
  * Implemented by ElfSundae in [#4537](https://github.com/AFNetworking/AFNetworking/pull/4537).
* Missing tvOS compatibility for some methods.
  * Implemented by ElfSundae in [#4536](https://github.com/AFNetworking/AFNetworking/pull/4536).
* Missing `FOUNDATION_EXPORT` for `AFJSONObjectByRemovingKeysWithNullValues`.
  * Implemented by ElfSundae in [#4529](https://github.com/AFNetworking/AFNetworking/pull/4529).
  
#### Removed
* Unused UIImage+AFNetworking.h file.
  * Implemented by ElfSundae in [#4535](https://github.com/AFNetworking/AFNetworking/pull/4535).
