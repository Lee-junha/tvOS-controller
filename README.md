[![Language](https://img.shields.io/badge/Language-Swift3.0-brightgreen.svg?style=flat)](https://developer.apple.com/swift/)
[![Platforms iOS | tvOS](https://img.shields.io/badge/Platform-iOS%20%7C%20tvOS-lightgrey.svg?style=flat)](https://developer.apple.com/swift/)
[![License MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=flat)](https://github.com/fluidpixel/tvOS-controller/blob/master/LICENSE)

# tvOS-controller
Control tvOS games &amp; apps from your iPhone

## Requirements 

- iOS 9.0+ / Mac OS X 10.11+
- Xcode 8 / Swift 3.0

## Platform Support

- iOS
- tvOS

## Integration

``` tvOS
let remote = TVCTVSession()
...
remote.delegate = self
...
extension YourClass: TVCTVSessionDelegate {
  //override delegate method
}
```

``` iOS
let remote = TVCPhoneSession()
...
remote.delegate = self
...
extension YourClass: TVCPhoneSessionDelegate {
  //override delegate method
}
```


##License
The MIT License (MIT)

Copyright (c) [2015] [Rob Reuss]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.



