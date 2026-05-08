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
    
    mapping(address => Device) public devices;
    address public admin;
    
    event DeviceRegistered(address indexed deviceAddress, string deviceId, uint256 timestamp);
    event DeviceAuthenticated(address indexed deviceAddress, string deviceId, uint256 timestamp);
    event DeviceRevoked(address indexed deviceAddress, string deviceId, uint256 timestamp);
    
    constructor() {
        admin = msg.sender;
    }
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyRegistered() {
        require(devices[msg.sender].isRegistered, "Device not registered");
        require(devices[msg.sender].isActive, "Device has been revoked");
        _;
    }
    
    function registerDevice(address _deviceAddress, string memory _deviceId) public onlyAdmin {
        require(!devices[_deviceAddress].isRegistered, "Device already registered");
        
        devices[_deviceAddress] = Device({
            deviceId: _deviceId,
            deviceAddress: _deviceAddress,
            isRegistered: true,
            isActive: true,
            registeredAt: block.timestamp
        });
        
        emit DeviceRegistered(_deviceAddress, _deviceId, block.timestamp);
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
    
    function revokeDevice(address _deviceAddress) public onlyAdmin {
        require(devices[_deviceAddress].isRegistered, "Device not registered");
        devices[_deviceAddress].isActive = false;
        emit DeviceRevoked(_deviceAddress, devices[_deviceAddress].deviceId, block.timestamp);
    }
    
    function isDeviceActive(address _deviceAddress) public view returns (bool) {
        return devices[_deviceAddress].isRegistered && devices[_deviceAddress].isActive;
    }
}