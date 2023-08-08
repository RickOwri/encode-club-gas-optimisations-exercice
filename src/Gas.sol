// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

contract GasContract {
    uint256 private totalSupply;
    bool private wasLastOdd = true;


    mapping(address => bool) public admins;
    
    mapping(uint8 => address) public administrators;
    
    mapping(address => uint256) public balances;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) private isOddWhitelistUser;
    mapping(address => ImportantStruct) private whiteListStruct;

    struct ImportantStruct {
        uint256 amount;
        bool paymentStatus;
        address sender;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event WhiteListTransfer(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        // totalSupply = _totalSupply;

        for (uint8 ii = 0; ii < _admins.length; ii++) {
            if (_admins[ii] != address(0)) {
                admins[_admins[ii]]=true;
                if (_admins[ii] == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                }         
            }
        }
    }

    function checkForAdmin(address _user, uint8 i) public view returns (bool _admin) {
        if (admins[_user]=true) {
            administrators[i]=_user;
            return true;
        }
    }

    function balanceOf(address _user) external view returns (uint256 balance_) {
        return balances[_user];
    }

    function transfer(
        address _recipient,
        uint256 _amount,
        string calldata _name
    ) public {
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
    }


    function addToWhitelist(address _userAddrs, uint256 _tier) external {
        // keep
        require(checkForAdmin(msg.sender), "Caller not admin");
        require(_tier < 255, "tier level greater than 255");
        // keep
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] = 2;
        } else {
            whitelist[_userAddrs] = _tier;
        }

        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external {
        whiteListStruct[msg.sender] = ImportantStruct(
            _amount,
            true,
            msg.sender
        );
        
        balances[msg.sender] -= (_amount - whitelist[msg.sender]);
        balances[_recipient] += (_amount - whitelist[msg.sender]);

        emit WhiteListTransfer(_recipient);
    }

    function getPaymentStatus(
        address sender
    ) external view returns (bool, uint256) {
        return (
            whiteListStruct[sender].paymentStatus,
            whiteListStruct[sender].amount
        );
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}
