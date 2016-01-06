import XCTest
import WebKit
@testable import Neeman

class WebViewNavigationDelegateTests: XCTestCase {
    
    var settings: Settings {
        get {
            let pathToSettings = NSBundle.init(forClass: WebViewNavigationDelegateTests.self).pathForResource("Settings", ofType: "plist")
            return Settings(path: pathToSettings)
        }
    }
    
    func testInitialRequest() {
        let url = NSURL(string: "http://example.com/")
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url!, delegate: nil, settings: settings)
        let request = NSURLRequest(URL: url!)
        XCTAssertFalse(navigationDelegate.shouldPushNewWebViewForRequest(request), "The initial request should not be pushed")
    }
    
    
    func testFaultyURLNavigation() {
        let url = NSURL(string: "http://example.com/")
        let urlFaulty = NSURL()
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url!, delegate: nil, settings: settings)
        let request = NSURLRequest(URL: urlFaulty)
        
        XCTAssertFalse(navigationDelegate.shouldPushNewWebViewForRequest(request), "Faulty URLs should not be pushed")
    }
    
    func testHashNavigation() {
        let url = NSURL(string: "http://example.com/#hash")
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url!, delegate: nil, settings: settings)
        let request = NSURLRequest(URL: url!)
        
        XCTAssertFalse(navigationDelegate.shouldPushNewWebViewForRequest(request), "Hash navigation should not be pushed")
    }
    
    func testNavigateForward() {
        let url1 = NSURL(string: "http://example.com/")
        let url2 = NSURL(string: "http://example.com/user/profile/me")
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url1!, delegate: nil, settings: settings)
        let request = NSURLRequest(URL: url2!)
        
        XCTAssertTrue(navigationDelegate.shouldPushNewWebViewForRequest(request), "New URLs should not be pushed")
    }
    
    // MARK: Delegation
    
    func testErrorPassedToDelegate() {
        let expectation = expectationWithDescription("Pass Error to Delegate")
        class MyNeemanWebViewController: NSObject, NeemanNavigationDelegate {
            var expectation: XCTestExpectation
            
            init(expectation: XCTestExpectation) {
                self.expectation = expectation
            }

            func webView(webView: WKWebView, didFinishLoadingWithError error: NSError) {
                XCTAssertNotNil(error, "The delegate should be passed a non nil error")
                expectation.fulfill()
            }
        }
        
        let url = NSURL(string: "https://groupdock.com/a/Level")
        let delegate = MyNeemanWebViewController(expectation: expectation)
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url!, delegate: delegate, settings: settings)
        let error = NSError(domain: "", code: 1, userInfo: nil)
        navigationDelegate.webView(WKWebView(), didFailProvisionalNavigation: nil, withError: error)
        
        waitForExpectationsWithTimeout(1) { (error: NSError?) -> Void in
            if let _ = error {
                XCTFail("Error Passing Failed")
            }
        }
    }
    
    func testDecidePolicyForNavigationAction() {
        let expectation = expectationWithDescription("Call Callback")
        let url = NSURL(string: "https://groupdock.com/a/Level")
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url!, delegate: nil, settings: settings)
        let request = NSURLRequest(URL: url!)
        let navigationAction = NavigationAction(request: request)
        navigationDelegate.webView(WKWebView(), decidePolicyForNavigationAction: navigationAction) { (policy: WKNavigationActionPolicy) -> Void in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(1) { (error: NSError?) -> Void in
            if let _ = error {
                XCTFail("Error Passing Failed")
            }
        }
    }
    
    func testShouldPreventPushOfNewWebView() {
        class MyWKNavigation: NSObject {
        }
        class MyNeemanWebViewController: NSObject, NeemanNavigationDelegate {
            func shouldPreventPushOfNewWebView(request: NSURLRequest) -> Bool {
                return true
            }
        }
        
        let url = NSURL(string: "https://groupdock.com/a/Level")
        let delegate = MyNeemanWebViewController()
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url!, delegate: delegate, settings: settings)
        navigationDelegate.shouldPushNewWebViewForRequest(NSURLRequest(URL:url!))
    }
    
    func testDelegateDefaultImplementations() {
        class MyNeemanWebViewController: NSObject, NeemanNavigationDelegate {
        }
        
        let webView = WKWebView()
        let delegate = MyNeemanWebViewController()
        delegate.webView(webView, didFinishNavigationWithURL:nil)
        delegate.webView(webView, didFinishLoadingWithError: NSError(domain: "", code: 1, userInfo: nil))
        delegate.webView(webView, didReceiveServerRedirectToURL: nil)
        delegate.shouldForcePushOfNewRequest(NSURLRequest())
        delegate.pushNewWebViewControllerWithURL(NSURL())
        delegate.shouldPreventPushOfNewWebView(NSURLRequest())
    }
    
    func testDelegateMethodsCalled() {
        let expectation = expectationWithDescription("Pass Error to Delegate")
        class NeemanWebViewController: MyNeemanWebViewController {
            override func webView(webView: WKWebView, didFinishNavigationWithURL: NSURL?) {
                expectation.fulfill()
            }
        }
        
        let url = NSURL(string: "https://intellum.com/cool/new/link")!
        let delegate = NeemanWebViewController(expectation: expectation)
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url, delegate: delegate, settings: settings)
        
        navigationDelegate.webView(WKWebView(), didFinishNavigation: nil)

        waitForExpectationsWithTimeout(1) { (error: NSError?) -> Void in
            if let _ = error {
                XCTFail("Error Passing Failed")
            }
        }
    }
    
    func testDelegateRedirectMethodsCalled() {
        let expectation = expectationWithDescription("Pass Error to Delegate")
//        class NeemanWebViewController: MyNeemanWebViewController {
        class NeemanWebViewController: MyNeemanWebViewController {
            override func webView(webView: WKWebView, didReceiveServerRedirectToURL: NSURL?) {
                self.expectation.fulfill()
            }
        }
        
        let url = NSURL(string: "https://intellum.com/cool/new/link")!
        let delegate = NeemanWebViewController(expectation: expectation)
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url, delegate: delegate, settings: settings)
        
        navigationDelegate.webView(WKWebView(), didReceiveServerRedirectForProvisionalNavigation: nil)
        
        waitForExpectationsWithTimeout(1) { (error: NSError?) -> Void in
            if let _ = error {
                XCTFail("Error Passing Failed")
            }
        }
    }
    
    func testPushIsCalled() {
        let expectation = expectationWithDescription("Pass Error to Delegate")
        class NeemanWebViewController: MyNeemanWebViewController {
            override func shouldForcePushOfNewRequest(request: NSURLRequest) -> Bool {
                return true
            }
            override func pushNewWebViewControllerWithURL(url: NSURL) {
                expectation.fulfill()
            }
        }
        class MyWKNavigationAction: NavigationAction {
            override var navigationType: WKNavigationType {
                get {
                    return .LinkActivated
                }
            }
        }
        
        let url = NSURL(string: "https://intellum.com/cool/new/link")!
        let delegate = NeemanWebViewController(expectation: expectation)
        let navigationDelegate = WebViewNavigationDelegate(rootURL: url, delegate: delegate, settings: settings)
        let action = MyWKNavigationAction(request: NSURLRequest(URL: url))

        
        navigationDelegate.webView(WKWebView(), decidePolicyForNavigationAction: action) { (WKNavigationActionPolicy) -> Void in
            
        }
        
        waitForExpectationsWithTimeout(1) { (error: NSError?) -> Void in
            if let _ = error {
                XCTFail("Error Passing Failed")
            }
        }
    }
}

class MyNeemanWebViewController: NSObject, NeemanNavigationDelegate {
    var expectation: XCTestExpectation
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func webView(webView: WKWebView, didReceiveServerRedirectToURL: NSURL?) {}
    func webView(webView: WKWebView, didFinishNavigationWithURL: NSURL?) {}
    func shouldForcePushOfNewRequest(request: NSURLRequest) -> Bool {
        return false
    }
    func pushNewWebViewControllerWithURL(url: NSURL) {}
}

class NavigationAction: WKNavigationAction {
    var myRequest: NSURLRequest
    override var request: NSURLRequest {
        get {
            return myRequest
        }
    }
    override var navigationType: WKNavigationType {
        get {
            return .LinkActivated
        }
    }
    init(request: NSURLRequest) {
        myRequest = request
    }
}
