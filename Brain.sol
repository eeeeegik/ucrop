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
    bool public canBeClosedOnlyByClient = true; //флаг, что CDP может быть закрыт только покупателем токенов
    uint256 tokenAmount;

    constructor (uint256 _maxUcropValue, uint256 _lastRateInfo, address _clientAddress) public {
        maxUcropValue = _maxUcropValue;
        lastRateInfo = _lastRateInfo;
        clientAddress = _clientAddress;
        tokenAmount = calcTokenAmount(_lastRateInfo);
        generateUcropTokens(tokenAmount);
    }
    
    function calcTokenAmount(uint _lastEtherRateInfo)
    internal 
    returns (uint256 calculatedTokenAmount)
    {
        uint256 a = ( uint(_lastEtherRateInfo) / 2); //двойное крипто-обеспечение 
        return a; //выдаем токенов в два раза меньше стоимости внесенного эфира
    }
    
    function getRateInfo(uint _1EtherCost) 
        external
        onlyOwner
    {
        lastRateInfo = _1EtherCost;
        
        //в случае, если курс Эфира ниже допустимого минимума
        if(lastRateInfo < 75)
        {
            toAuctionOff();
        }
    }

    //выставление содержимого CDP на открытый аукцион
    function toAuctionOff()
        private
    {
        canBeClosedOnlyByClient = false;
    }
    
    function generateUcropTokens(uint _tokenAmount)
        private
    {
        ;
    }
    
    function() payable {
        UcropToken u = new UcropToken();
        uint256 weiAmount = msg.value;
        uint256 tokens = tokenAmount;
        //??
        u.mint(msg.sender, tokens); // пробую написать специальную функцию генерации токенов в CDP
        
    }
    


  
}


contract UcropToken is Ownable{
    
    string public constant name = "Ucrop token";
    string public constant symbol = "ucr";
    uint32 constant public decimals = 18;
    //uint rate; 
    uint256 public totalSupply ;
    mapping(address=>uint256) public balances;
    
    mapping (address => mapping(address => uint)) allowed;
    
   

  function mint(address  _to, uint _value) internal {
    assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
    balances[_to] += _value;
    totalSupply += _value;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function transfer(address _to, uint _value) public returns (bool success) {
    if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
      balances[msg.sender] -= _value;
      balances[_to] += _value;
      Transfer(msg.sender, _to, _value);
      return true;
    }
    return false;
  }

  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    if( allowed[_from][msg.sender] >= _value &&
    balances[_from] >= _value
    && balances[_to] + _value >= balances[_to]) {
      allowed[_from][msg.sender] -= _value;
      balances[_from] -= _value;
      balances[_to] += _value;
      Transfer(_from, _to, _value);
      return true;
    }
    return false;
  }

  function approve(address _spender, uint _value) public returns (bool success) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  event Transfer(address indexed _from, address indexed _to, uint _value);

  event Approval(address indexed _owner, address indexed _spender, uint _value);

  /*function getTokenAmount(uint256 _value) internal view returns (uint256) {
    return _value * rate;
  }*/

  /*function () payable {
    uint256 weiAmount = msg.value;
    uint256 tokens = getTokenAmount(weiAmount);
    mint(msg.sender, tokens);
  }*/

}
