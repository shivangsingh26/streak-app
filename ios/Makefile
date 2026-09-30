PROJECT = DSAMatrix.xcodeproj
SCHEME  = DSAMatrix
SIM    ?= iPhone 17
DEST    = platform=iOS Simulator,name=$(SIM)
DERIVED = build
APP     = $(DERIVED)/Build/Products/Debug-iphonesimulator/DSAMatrix.app
XCB     = xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -derivedDataPath $(DERIVED)

.PHONY: generate build test run shots

generate:
	xcodegen generate --quiet

build: generate
	$(XCB) build -quiet

test: generate
	$(XCB) test -quiet -only-testing:DSAMatrixTests

run: build
	xcrun simctl boot '$(SIM)' 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted $(APP)
	xcrun simctl launch --terminate-running-process booted com.shivangsingh.dsamatrix $(ARGS)

shots: generate
	rm -rf $(DERIVED)/shots.xcresult shots
	$(XCB) test -quiet -only-testing:DSAMatrixUITests -resultBundlePath $(DERIVED)/shots.xcresult
	xcrun xcresulttool export attachments --path $(DERIVED)/shots.xcresult --output-path shots
