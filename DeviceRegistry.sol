// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DeviceRegistry {
    
    struct Device {
        string deviceId;
        address deviceAddress;
        bool isRegistered;
        bool isActive;
        uint256 registeredAt;
    }
    
    struct RegistrationRequest {
        address deviceAddress;
        string deviceId;
        uint256 approvalCount;
        bool executed;
        mapping(address => bool) hasVoted;
    }
    
    mapping(address => Device) public devices;
    mapping(uint256 => RegistrationRequest) public requests;
    uint256 public requestCount;
    
    address[] public validators;
    uint256 public threshold;
    
    event DeviceRegistered(address indexed deviceAddress, string deviceId, uint256 timestamp);
    event DeviceAuthenticated(address indexed deviceAddress, string deviceId, uint256 timestamp);
    event DeviceRevoked(address indexed deviceAddress, string deviceId, uint256 timestamp);
    event RegistrationRequested(uint256 indexed requestId, address deviceAddress, string deviceId);
    event RegistrationApproved(uint256 indexed requestId, address validator);
    
    constructor(address[] memory _validators, uint256 _threshold) {
        require(_validators.length >= _threshold, "Threshold exceeds validator count");
        require(_threshold > 0, "Threshold must be greater than zero");
        validators = _validators;
        threshold = _threshold;
    }
    
    modifier onlyValidator() {
        bool isValidator = false;
        for (uint256 i = 0; i < validators.length; i++) {
            if (validators[i] == msg.sender) {
                isValidator = true;
                break;
            }
        }
        require(isValidator, "Only validators can perform this action");
        _;
    }
    
    modifier onlyRegistered() {
        require(devices[msg.sender].isRegistered, "Device not registered");
        require(devices[msg.sender].isActive, "Device has been revoked");
        _;
    }
    
    function requestRegistration(address _deviceAddress, string memory _deviceId) public onlyValidator {
        require(!devices[_deviceAddress].isRegistered, "Device already registered");
        
        uint256 requestId = requestCount++;
        RegistrationRequest storage request = requests[requestId];
        request.deviceAddress = _deviceAddress;
        request.deviceId = _deviceId;
        request.approvalCount = 0;
        request.executed = false;
        
        emit RegistrationRequested(requestId, _deviceAddress, _deviceId);
    }
    
    function approveRegistration(uint256 _requestId) public onlyValidator {
        RegistrationRequest storage request = requests[_requestId];
        require(!request.executed, "Request already executed");
        require(!request.hasVoted[msg.sender], "Validator already voted");
        
        request.hasVoted[msg.sender] = true;
        request.approvalCount++;
        
        emit RegistrationApproved(_requestId, msg.sender);
        
        if (request.approvalCount >= threshold) {
            request.executed = true;
            devices[request.deviceAddress] = Device({
                deviceId: request.deviceId,
                deviceAddress: request.deviceAddress,
                isRegistered: true,
                isActive: true,
                registeredAt: block.timestamp
            });
            emit DeviceRegistered(request.deviceAddress, request.deviceId, block.timestamp);
        }
    }
    
    function authenticateDevice(string memory _deviceId) public onlyRegistered returns (bool) {
        Device storage device = devices[msg.sender];
        require(
            keccak256(abi.encodePacked(device.deviceId)) == keccak256(abi.encodePacked(_deviceId)),
            "Device ID mismatch"
        );
        emit DeviceAuthenticated(msg.sender, _deviceId, block.timestamp);
        return true;
    }
    
    function revokeDevice(address _deviceAddress) public onlyValidator {
        require(devices[_deviceAddress].isRegistered, "Device not registered");
        devices[_deviceAddress].isActive = false;
        emit DeviceRevoked(_deviceAddress, devices[_deviceAddress].deviceId, block.timestamp);
    }
    
    function isDeviceActive(address _deviceAddress) public view returns (bool) {
        return devices[_deviceAddress].isRegistered && devices[_deviceAddress].isActive;
    }
    
    function getValidators() public view returns (address[] memory) {
        return validators;
    }
}
