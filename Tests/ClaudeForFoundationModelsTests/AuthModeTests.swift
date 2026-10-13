// Copyright 2026 Anthropic PBC
// SPDX-License-Identifier: Apache-2.0

import Foundation
import Testing

@testable import ClaudeForFoundationModels

@Suite struct AuthModeTests {
  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `proxied modes differ by their headers`() {
    #expect(AuthMode.proxied(headers: ["a": "1"]) == AuthMode.proxied(headers: ["a": "1"]))
    #expect(AuthMode.proxied(headers: ["a": "1"]) != AuthMode.proxied(headers: ["a": "2"]))
    #expect(AuthMode.proxied(headers: [:]) != AuthMode.apiKey("k"))
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `appAttest identity is the client id`() {
    #expect(AuthMode.appAttest(clientID: "a") == AuthMode.appAttest(clientID: "a"))
    #expect(AuthMode.appAttest(clientID: "a") != AuthMode.appAttest(clientID: "b"))
  }

  /// Proxy headers must participate in the executor cache key, so two models
  /// that differ only by their proxy headers get distinct cached executors.
  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `proxy headers drive the executor configuration identity`() {
    @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
    func config(_ auth: AuthMode) -> ClaudeExecutor.Configuration {
      .init(
        model: .sonnet4_6,
        baseURL: ClaudeLanguageModel.defaultBaseURL,
        authMode: auth,
        timeout: 60
      )
    }
    #expect(config(.proxied(headers: ["a": "1"])) == config(.proxied(headers: ["a": "1"])))
    #expect(config(.proxied(headers: ["a": "1"])) != config(.proxied(headers: ["a": "2"])))
  }
}
