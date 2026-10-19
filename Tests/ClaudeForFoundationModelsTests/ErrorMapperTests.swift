// Copyright 2026 Anthropic PBC
// SPDX-License-Identifier: Apache-2.0

import ClaudeAPI
import Foundation
import FoundationModels
import Testing

@testable import ClaudeForFoundationModels

@Suite struct ErrorMapperTests {
  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  private func mapped(
    _ kind: APIError.Kind,
    _ message: String = "boom",
    requestID: String? = nil
  )
    -> any Error
  {
    ErrorMapper.map(
      APIError(kind: kind, message: message, requestID: requestID),
      usesAppAttest: false
    )
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `rate limit becomes rateLimited with no reset date`() {
    guard case LanguageModelError.rateLimited(let payload) = mapped(.rateLimit, "slow down") else {
      Issue.record("expected rateLimited")
      return
    }
    #expect(payload.resetDate == nil)
    #expect(payload.debugDescription.contains("slow down"))
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `overloaded becomes rateLimited with no fabricated reset date`() {
    guard case LanguageModelError.rateLimited(let payload) = mapped(.overloaded) else {
      Issue.record("expected rateLimited")
      return
    }
    // The API doesn't say when capacity returns, so neither do we.
    #expect(payload.resetDate == nil)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `request too large becomes contextSizeExceeded`() {
    guard case LanguageModelError.contextSizeExceeded = mapped(.requestTooLarge) else {
      Issue.record("expected contextSizeExceeded")
      return
    }
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `invalid request mentioning context becomes contextSizeExceeded`() {
    guard
      case LanguageModelError.contextSizeExceeded = mapped(
        .invalidRequest,
        "Context length exceeded"
      )
    else {
      Issue.record("expected contextSizeExceeded")
      return
    }
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `plain invalid request passes through unchanged`() {
    #expect((mapped(.invalidRequest, "missing field") as? APIError)?.kind == .invalidRequest)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `not found passes through unchanged`() {
    #expect((mapped(.notFound) as? APIError)?.kind == .notFound)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `authentication becomes missingCredential`() {
    guard case ClaudeError.missingCredential = mapped(.authentication) else {
      Issue.record("expected missingCredential for auth")
      return
    }
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `permission passes through unchanged`() {
    // A valid credential without access is not a missing credential — keep
    // the API's own message so the developer sees what was denied.
    #expect((mapped(.permission) as? APIError)?.kind == .permission)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `generic api error passes through unchanged`() {
    #expect((mapped(.api, "internal error") as? APIError)?.kind == .api)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `request id is folded into the debug description`() {
    guard
      case LanguageModelError.rateLimited(let payload) = mapped(
        .rateLimit,
        "slow",
        requestID: "req_9"
      )
    else {
      Issue.record("expected rateLimited")
      return
    }
    #expect(payload.debugDescription.contains("req_9"))
    #expect(payload.debugDescription.contains("slow"))
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `URLError timeout becomes a LanguageModelError timeout`() {
    guard
      case LanguageModelError.timeout = ErrorMapper.map(URLError(.timedOut), usesAppAttest: false)
    else {
      Issue.record("expected timeout")
      return
    }
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `a non-timeout URLError passes through unchanged`() {
    let original = URLError(.notConnectedToInternet)
    #expect(
      (ErrorMapper.map(original, usesAppAttest: false) as? URLError)?.code
        == .notConnectedToInternet
    )
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `an unrecognized API error kind passes through as the APIError`() {
    #expect((mapped(.other, "novel failure") as? APIError)?.kind == .other)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `image preparation failures map to unsupportedTranscriptContent`() {
    guard
      case LanguageModelError.unsupportedTranscriptContent(let payload) = ErrorMapper.map(
        ClaudeImage.Error.tooLarge(byteCount: 99),
        usesAppAttest: false
      )
    else {
      Issue.record("expected unsupportedTranscriptContent")
      return
    }
    #expect(payload.debugDescription.contains("99"))
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `unrecognized errors pass through unchanged`() {
    struct Marker: Error {}
    #expect(ErrorMapper.map(Marker(), usesAppAttest: false) is Marker)
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `unsupported attestation becomes attestationUnsupported`() {
    guard case ClaudeError.attestationUnsupported = ErrorMapper.map(AppAttestError.unsupported)
    else {
      Issue.record("expected attestationUnsupported")
      return
    }
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `other attestation failures become attestationFailed`() {
    for error in [AppAttestError.notYetAvailable, .keyInvalidated] {
      guard case ClaudeError.attestationFailed = ErrorMapper.map(error, usesAppAttest: false) else {
        Issue.record("expected attestationFailed for \(error)")
        return
      }
    }
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `attestationFailed carries the failing endpoint and status as its reason`() {
    let mapped = ErrorMapper.map(
      AppAttestError.requestFailed(endpoint: .register, status: 403, retryAfter: nil)
    )
    #expect(
      mapped.errorDescription
        == "App attestation failed to produce a credential. (App Attest register request failed (HTTP 403).)"
    )
  }

  @available(iOS 27.0, macOS 27.0, visionOS 27.0, watchOS 27.0, *)
  @Test func `rejected credential under appAttest carries the server message as its reason`() {
    let mapped = ErrorMapper.map(
      APIError(kind: .authentication, message: "invalid client", requestID: "req_1"),
      usesAppAttest: true
    )
    guard case ClaudeError.attestationFailed(let reason) = mapped else {
      Issue.record("expected attestationFailed, got \(mapped)")
      return
    }
    #expect(reason == "invalid client (request_id: req_1)")
  }
}
