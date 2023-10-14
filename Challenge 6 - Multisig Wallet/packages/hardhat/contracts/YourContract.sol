// SPDX-License-Identifier: GPL-3.0
///https://www.youtube.com/watch?v=Yx0oifA9j6I

pragma solidity  ^0.8.0;

contract YourContract {

    ////////////SMART CONTRACT EVENTS////////////

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);


    ////////////SMART CONTRACT VARIABLES////////////
    address [] public owners; //List of owners

    mapping(address => bool) public isOwner; //Quickly identify if and address is owner of the multisig

    uint256 public requiredOwnersApprovals; //Number of approvals needes before a transaction can be executed

    //Store the transaction information in a struct
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction [] public transactions; //Array of transactions. Every transaction can be executed if it meets the required amount of validations

    mapping(uint256 => mapping(address => bool)) public approved; //Transaction Number => (Owner address => boolean if approved or not)

    ////////////SMART CONTRACT MODIFIERS////////////

    modifier onlyOwner(){
        require (isOwner[msg.sender] == true, "The sender is not an owner");
        _;
    }

    modifier txExists(uint256 _txId) {
        require (transactions[_txId].value > 0, "The transaction doesnt exist");
        _;
    }
    
    modifier notApproved(uint256 _txId) {
        require (approved[_txId][msg.sender] == false, "The transaction is already approved by this sender");
        _;
    }
    
    modifier notExecuted(uint256 _txId) {
        require (transactions[_txId].executed == false, "The transaction is already executed");
        _;
    }

    ////////////SMART CONTRACT CONSTRUCTOR////////////

    constructor(address [] memory _owners, uint256 _requiredOwnerApprovals) {

        require(_owners.length > 0, "There must be at least one owner");

        require(_requiredOwnerApprovals > 0 && _requiredOwnerApprovals <= _owners.length, "Invalid required number of owners");

        for(uint256 i=0; i<_owners.length; i++) {

            address tempOwner = _owners[i];
            require(tempOwner != address(0), "Invalid owner address");
            require(isOwner[tempOwner] == false, "Owner to be added is already in the list of owners");
            
            isOwner[tempOwner] = true;
            owners.push(tempOwner);
        }

        requiredOwnersApprovals = _requiredOwnerApprovals;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit (address _to, uint256 _value, bytes calldata _data) external onlyOwner {
        transactions.push(Transaction({
            to: _to, 
            value: _value, 
            data: _data, 
            executed: false}
        ));

        emit Submit(transactions.length-1);
    }

    function approve(uint256 _txId) external onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        
        approved[_txId][msg.sender] = true;
        emit Approve (msg.sender, _txId);
    }


    function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {

        for(uint256 i=0; i<owners.length; i++) {

            if( approved[_txId][owners[i]] == true){
                count++;
            }
        }
    }

    function execute (uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId)  {
        require( _getApprovalCount(_txId) >= requiredOwnersApprovals, "The approvals of the transaction is less than required");

        address _to = transactions[_txId].to;
        uint256 _value = transactions[_txId].value;
        bytes memory _data = transactions[_txId].data;

        transactions[_txId].executed = true;
        
        (bool executed,) = _to.call{value: _value}(_data);

        require(executed, "There was an error in the transaction execution");

        emit Execute(_txId);
    }

    function revoke(uint256 _txId) external onlyOwner txExists(_txId) notExecuted(_txId) {
        require(approved[_txId][msg.sender] == true, "The transaccion has not been approved");

        approved[_txId][msg.sender] == false;

        emit Revoke(msg.sender, _txId);
    }
}