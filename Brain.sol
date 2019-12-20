pragma solidity ^0.4.11;

contract Brain {
    
    uint256 public tokensAmount = 0;
    uint256 public maxUcropPerCDPValue = 100;
    uint256 public maxUcropPerClient = 1000;
    
    mapping(address=>uint256) public tokensPerClient; //учет количества токенов по каждому клиенту
    address[] public contracts; // index of created contracts

    function getContractCount() // useful to know the row count in contracts index
        public
        constant
        returns(uint contractCount)
    {
        return contracts.length;
    }
    
    modifier isLimit(uint256 _amountToGet) {
        require(_amountToGet <= maxUcropPerCDPValue && _amountToGet > 0, "Желаемое количество превышает максимально возможное для одного CDP");
        require(tokensPerClient[msg.sender] + _amountToGet <= maxUcropPerClient, "Желаемое количество превышает максимально возможное для одного клиента");
        _;
    }
    
// initialize deploying of a new contract
//аргумент - количество токенов, которое пользователь желает взять в кредит из CDP
// возможно, есть смысл проводить какие-то проверки пользователей в этой функции
    function getNewCDP(uint256 _amountToGet) 
        isLimit(_amountToGet)
        public 
        returns(address newCDP) 
    {
        return createNewCDP(_amountToGet);
    }

    function createNewCDP(uint256 _maxUcropValue) //deploy a new contract
        private
        returns(address newContract)
    {
        CDP c = new CDP(_maxUcropValue);
        contracts.push(c);
        tokensAmount++;
        return c;
    }
    
}

contract CDP {
    
    uint256 public maxUcropValue;

    constructor (uint256 _maxUcropValue) public {
        maxUcropValue = _maxUcropValue;
    }

  
}
