// Copyright 2018-2022 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//
//  HTTPClientInvocationContext.swift
//  SmokeHTTPClient
//

import Foundation
import Logging
import Metrics

private let outgoingRequestId = "outgoingRequestId"
private let outgoingEndpointKey = "outgoingEndpoint"
private let outgoingOperationKey = "outgoingOperation"

/**
 A context related to the invocation of the HTTPClient.
 */
public struct HTTPClientInvocationContext<InvocationReportingType: HTTPClientInvocationReporting, HandlerDelegateType: HTTPClientInvocationDelegate> {
    public let reporting: InvocationReportingType
    public let handlerDelegate: HandlerDelegateType
    
    public init(reporting: InvocationReportingType,
                handlerDelegate: HandlerDelegateType) {
        self.reporting = reporting
        self.handlerDelegate = handlerDelegate
    }
}

extension HTTPClientInvocationContext {
    func withOutgoingDecoratedLogger(endpoint endpointOptional: URL?, outgoingOperation outgoingOperationOptional: String?)
    -> HTTPClientInvocationContext<StandardHTTPClientInvocationReporting<InvocationReportingType.TraceContextType>, HandlerDelegateType> {
        var outwardInvocationLogger = reporting.logger
        outwardInvocationLogger[metadataKey: outgoingRequestId] = "\(UUID().uuidString)"
                
        if let endpoint = endpointOptional {
            outwardInvocationLogger[metadataKey: outgoingEndpointKey] = "\(endpoint.absoluteString)"
        }
                
        if let outgoingOperation = outgoingOperationOptional {
            outwardInvocationLogger[metadataKey: outgoingOperationKey] = "\(outgoingOperation)"
        }
        
        let wrappingInvocationReporting = StandardHTTPClientInvocationReporting(
            internalRequestId: reporting.internalRequestId,
            traceContext: reporting.traceContext,
            logger: outwardInvocationLogger,
            eventLoop: reporting.eventLoop,
            outwardsRequestAggregator: reporting.outwardsRequestAggregator,
            successCounter: reporting.successCounter,
            failure5XXCounter: reporting.failure5XXCounter,
            failure4XXCounter: reporting.failure4XXCounter,
            retryCountRecorder: reporting.retryCountRecorder,
            latencyTimer: reporting.latencyTimer)
        return HTTPClientInvocationContext<StandardHTTPClientInvocationReporting<InvocationReportingType.TraceContextType>,
                HandlerDelegateType>(reporting: wrappingInvocationReporting,
                                     handlerDelegate: handlerDelegate)
    }
}
