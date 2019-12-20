pragma solidity ^0.4.11;

contract Ownable {

  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Только owner может вызвать эту функцию");
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    owner = newOwner;
  }

}

contract Brain is Ownable{
    
    uint256 public tokensAmount = 0;
    uint256 public maxUcropPerCDPValue = 100;
    uint256 public maxUcropPerClient = 1000;
    uint256 public lastEtherRateInfo = 111;
    
    mapping(address=>uint256) public tokensPerClient; //учет количества токенов по каждому клиенту
    address[] public contracts; // index of created contracts

    function getContractCount() // useful to know the row count in contracts index
        public
        constant
        returns(uint CDPCount)
    {
        return contracts.length;
    }
    
    modifier isLimit(uint256 _amountToGet) {
        require(_amountToGet <= maxUcropPerCDPValue && _amountToGet > 0, "Желаемое количество превышает максимально возможное для одного CDP");
        require(tokensPerClient[msg.sender] + _amountToGet <= maxUcropPerClient, "Желаемое количество превышает максимально возможное для одного клиента");
        _;
    }

    function createNewCDP(uint256 _amountToGet) //deploy a new contract
        isLimit(_amountToGet)
        public
        returns(address newCDP)
    {
        CDP c = new CDP(_amountToGet, lastEtherRateInfo, msg.sender);
        contracts.push(c);
        tokensAmount++;
        return c;
    }
    
    //информация о курсе валюты
    function broadcastRate(uint _1EtherCost)
        public
        onlyOwner
    {
        for(uint i=0; i < contracts.length; i++)
        {
            CDP existingCDP = CDP(contracts[i]); //обращаемся к каждому адресу существующих CDP
            existingCDP.getRateInfo(_1EtherCost); //сообщаем им информацию о курсе эфира
        }
        lastEtherRateInfo = _1EtherCost;
    }
    
}

contract CDP is Ownable{
    
    uint256 public maxUcropValue; //максимальное количество токенов, которые можно приобрести
    uint256 public lastRateInfo; //последняя полученная информация о курсе Эфира
    address public clientAddress; //адрес покупателя токенов

    constructor (uint256 _maxUcropValue, uint256 _lastRateInfo, address _clientAddress) public {
        maxUcropValue = _maxUcropValue;
        lastRateInfo = _lastRateInfo;
        clientAddress = _clientAddress;
    }
    
    function getRateInfo(uint _1EtherCost) 
        external
        onlyOwner
    {
        lastRateInfo = _1EtherCost;
    }

  
}
