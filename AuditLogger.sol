// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract AuditLogger {
    
    struct AuditEvent {
        address deviceAddress;
        string eventType;
        string deviceId;
        uint256 timestamp;
        bool success;
    }
    
    AuditEvent[] public auditLog;
    address public admin;
    
    event LogEntry(
        address indexed deviceAddress,
        string eventType,
        string deviceId,
        uint256 timestamp,
        bool success
    );
    
    constructor() {
        admin = msg.sender;
    }
    
    function logEvent(
        address _deviceAddress,
        string memory _eventType,
        string memory _deviceId,
        bool _success
    ) public {
        AuditEvent memory newEvent = AuditEvent({
            deviceAddress: _deviceAddress,
            eventType: _eventType,
            deviceId: _deviceId,
            timestamp: block.timestamp,
            success: _success
        });
        
        auditLog.push(newEvent);
        
        emit LogEntry(
            _deviceAddress,
            _eventType,
            _deviceId,
            block.timestamp,
            _success
        );
    }
    
    function getLogCount() public view returns (uint256) {
        return auditLog.length;
    }
    
    function getLogEntry(uint256 _index) public view returns (
        address deviceAddress,
        string memory eventType,
        string memory deviceId,
        uint256 timestamp,
        bool success
    ) {
        require(_index < auditLog.length, "Index out of bounds");
        AuditEvent storage entry = auditLog[_index];
        return (
            entry.deviceAddress,
            entry.eventType,
            entry.deviceId,
            entry.timestamp,
            entry.success
        );
    }
}