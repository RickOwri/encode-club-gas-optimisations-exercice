// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "./Ownable.sol";



contract GasContract is Ownable {
    uint256 private totalSupply; // cannot be updated
    uint256 private paymentCounter = 0;
    address[5] public administrators;
    bool private wasLastOdd = true;

    mapping(address => uint256) public balances;
    mapping(address => mapping(uint256 => Payment)) private payments;
    mapping(address => uint256) public whitelist;
    mapping(address => bool) private isOddWhitelistUser;
    mapping(address => ImportantStruct) private whiteListStruct;

    enum PaymentType {
        Unknown,
        BasicPayment,
        Refund,
        Dividend,
        GroupPayment
    }
    
    struct Payment {
        uint256 amount;
        address recipient;
        bool adminUpdated;
        PaymentType paymentType;
        address admin; // administrators address
        // TODO: use bytes32 instead
        string recipientName; // max 8 characters 
    }
    
    struct ImportantStruct {
        uint256 amount;
        uint256 valueA; // max 3 digits
        uint256 bigValue;
        uint256 valueB; // max 3 digits
        bool paymentStatus;
        address sender;
    }

    modifier checkIfWhiteListed(address sender) {
        require(
            msg.sender == sender,
            "originator not sender"
        );
        uint256 usersTier = whitelist[msg.sender];
        require(
            usersTier > 0,
            "user not whitelisted"
        );
        require(
            usersTier < 4,
            "usersTier invalid"
        );
        _;
    }

    event AddedToWhitelist(address userAddress, uint256 tier);
    event supplyChanged(address indexed, uint256 indexed);
    event Transfer(address recipient, uint256 amount);
    event PaymentUpdated(
        address admin,
        uint256 ID,
        uint256 amount,
        // TODO: use bytes32 instead
        string recipient
    );
    event WhiteListTransfer(address indexed);
    event PaymentHistory(address indexed);

    constructor(address[] memory _admins, uint256 _totalSupply) {
        totalSupply = _totalSupply;

        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (_admins[ii] != address(0)) {
                administrators[ii] = _admins[ii];
                if (_admins[ii] == msg.sender) {
                    balances[msg.sender] = _totalSupply;
                    emit supplyChanged(_admins[ii], _totalSupply);
                } else {
                    balances[_admins[ii]] = 0;
                    emit supplyChanged(_admins[ii], 0);
                }
            }
        }
    }

    function checkForAdmin(address _user) public view returns (bool admin_) {
        for (uint256 ii = 0; ii < administrators.length; ii++) {
            if (administrators[ii] == _user) {
                return true;
            }
        }
        return false;
    }


    function balanceOf(address _user) external view returns (uint256 balance_) {
        return balances[_user];
    }


    function transfer(
        address _recipient,
        uint256 _amount,
        // TODO: use bytes32 instead
        string calldata _name
    ) public returns (bool status_) {
        require(
            balances[msg.sender] >= _amount,
            "Sender insufficient Balance"
        );
        require(
            bytes(_name).length < 9,
            "recipient name is too long, max length 8"
        );
        balances[msg.sender] -= _amount;
        balances[_recipient] += _amount;
        emit Transfer(_recipient, _amount);
        payments[msg.sender][paymentCounter].admin = address(0);
        payments[msg.sender][paymentCounter].adminUpdated = false;
        payments[msg.sender][paymentCounter].paymentType = PaymentType.BasicPayment;
        payments[msg.sender][paymentCounter].recipient = _recipient;
        payments[msg.sender][paymentCounter].amount = _amount;
        payments[msg.sender][paymentCounter].recipientName = _name;

        return true;
    }

    function updatePayment(
        address _user,
        uint256 _ID,
        uint256 _amount,
        PaymentType _type
    ) external {
        // require(
        //     checkForAdmin(msg.sender),
        //     "Caller not admin"
        // );
        // require(
        //     _ID > 0,
        //     "ID must be greater than 0"
        // );
        // require(
        //     _amount > 0,
        //     "Amount must be greater than 0"
        // );
        // require(
        //     _user != address(0),
        //     "Admin must have a valid address"
        // );

        payments[_user][_ID].adminUpdated = true;
        payments[_user][_ID].admin = _user;
        payments[_user][_ID].paymentType = _type;
        payments[_user][_ID].amount = _amount;

        emit PaymentHistory(_user);
        emit PaymentUpdated(
            msg.sender,
            _ID,
            _amount,
            payments[_user][_ID].recipientName
        );
    }

    function addToWhitelist(address _userAddrs, uint256 _tier)
        external
    {
        require(
            checkForAdmin(msg.sender),
            "Caller not admin"
        );
        require(
            _tier < 255,
            "tier level greater than 255"
        );
        
        if (_tier > 3) {
            whitelist[_userAddrs] = 3;
        } else if (_tier > 0 && _tier < 3) {
            whitelist[_userAddrs] = 2;
        } else {
            whitelist[_userAddrs] = _tier;
        }
        

        if (wasLastOdd) {
            isOddWhitelistUser[_userAddrs] = wasLastOdd;
            wasLastOdd = false;
        } else {
            isOddWhitelistUser[_userAddrs] = wasLastOdd;
            wasLastOdd = true;
        }
        emit AddedToWhitelist(_userAddrs, _tier);
    }

    function whiteTransfer(
        address _recipient,
        uint256 _amount
    ) external checkIfWhiteListed(msg.sender) {
        whiteListStruct[msg.sender] = ImportantStruct(_amount, 0, 0, 0, true, msg.sender);
        
        require(
            balances[msg.sender] >= _amount,
            "Sender has insufficient Balance"
        );
        require(
            _amount > 3,
            "amount to send have to be bigger than 3"
        );
        balances[msg.sender] -= (_amount- whitelist[msg.sender]);
        balances[_recipient] += (_amount - whitelist[msg.sender]);
        
        emit WhiteListTransfer(_recipient);
    }


    function getPaymentStatus(address sender) external view returns (bool, uint256) {
        return (whiteListStruct[sender].paymentStatus, whiteListStruct[sender].amount);
    }

    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}