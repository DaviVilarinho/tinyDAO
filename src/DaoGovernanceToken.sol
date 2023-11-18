pragma solidity >= 0.6;

import "OpenZeppelin/openzeppelin-contracts@3.0.0/contracts/token/ERC20/ERC20.sol";

// token da dao em si
contract DaoGovernanceToken is ERC20 {
  address owner;
  constructor(string memory tokenName, string memory tokenCode) ERC20(tokenName, tokenCode) {
    _mint(msg.sender, 1000);
  }

  event Rewarded(address who, uint daoTokens);
  event Punished(address who, uint daoTokens);

  function reward(address who, uint tokens) external {
    _mint(who, tokens); // so da mais token
    emit Rewarded(who, tokens);
  }

  function punish(address who, uint tokens) external {
    uint punishedBalance = balanceOf(who);
    if (tokens != 0) { // ignorar se lucro 0. So deixa emitido que foi punido como aviso pros proximos proposers que aqui eh coisa seria!!!
      if (punishedBalance < tokens) {
        _burn(who, tokens); // penaliza com o acordado
      } else {
        _burn(who, punishedBalance); // penaliza o maximo se nao tinha tokens
      }
    }
    emit Punished(who, tokens);
  }
}
