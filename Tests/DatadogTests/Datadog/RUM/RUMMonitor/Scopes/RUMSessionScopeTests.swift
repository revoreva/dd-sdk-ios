/*
 * Unless explicitly stated otherwise all files in this repository are licensed under the Apache License Version 2.0.
 * This product includes software developed at Datadog (https://www.datadoghq.com/).
 * Copyright 2019-2020 Datadog, Inc.
 */

import XCTest
@testable import Datadog

class RUMSessionScopeTests: XCTestCase {
    func testDefaultContext() {
        let parent: RUMApplicationScope = .mockWith(rumApplicationID: "rum-123")
        let scope = RUMSessionScope(parent: parent, dependencies: .mockAny())

        XCTAssertEqual(scope.context.rumApplicationID, "rum-123")
        XCTAssertNotEqual(scope.context.sessionID, RUMApplicationScope.Constants.nullUUID)
        XCTAssertNil(scope.context.activeViewID)
        XCTAssertNil(scope.context.activeViewURI)
        XCTAssertNil(scope.context.activeUserActionID)
    }

    func testWhenSessionExceedsMaxDuration_itGetsClosed() {
        let dateProvider = RelativeDateProvider()
        let parent = RUMScopeMock()
        let scope = RUMSessionScope(
            parent: parent,
            dependencies: .mockWith(dateProvider: dateProvider)
        )

        XCTAssertTrue(scope.process(command: .mockAny()))

        // Push time forward by the max session duration:
        dateProvider.advance(bySeconds: RUMSessionScope.Constants.sessionMaxDuration)

        XCTAssertFalse(scope.process(command: .mockAny()))
    }

    func testWhenSessionIsInactiveForCertainDuration_itGetsClosed() {
        let dateProvider = RelativeDateProvider()
        let parent = RUMScopeMock()
        let scope = RUMSessionScope(
            parent: parent,
            dependencies: .mockWith(dateProvider: dateProvider)
        )

        XCTAssertTrue(scope.process(command: .mockAny()))

        // Push time forward by less than the session timeout duration:
        dateProvider.advance(bySeconds: 0.5 * RUMSessionScope.Constants.sessionTimeoutDuration)

        XCTAssertTrue(scope.process(command: .mockAny()))

        // Push time forward by the session timeout duration:
        dateProvider.advance(bySeconds: RUMSessionScope.Constants.sessionTimeoutDuration)

        XCTAssertFalse(scope.process(command: .mockAny()))
    }
}