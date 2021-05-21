pragma solidity ^0.6.6;

import './UniswapV2Library.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IERC20.sol';

contract Arbitrage {
  address public pancakeFactory;
  uint constant deadline = 10 days;
  IUniswapV2Router02 public bakeryRouter;

  // Called from migration/deploy_contracts.js
  constructor(address _pancakeFactory, address _bakeryRouter) public {
    pancakeFactory = _pancakeFactory;  
    bakeryRouter = IUniswapV2Router02(_bakeryRouter);
  }


  // Entry Point, we may call this from a python script
  function startArbitrage(
    address token0, 
    address token1, 
    uint amount0, 
    uint amount1
  ) external {
    address pairAddress = IUniswapV2Factory(pancakeFactory).getPair(token0, token1);
    require(pairAddress != address(0), 'This pool does not exist');

    // Get the Flash Loan
    IUniswapV2Pair(pairAddress).swap(
      amount0, 
      amount1, 
      address(this), 
      bytes('not empty')
    );
  }


  // Called by pancake as response to our loan request.
  // Now we got the money.
  function pancakeCall(
    address _sender, 
    uint _amount0, 
    uint _amount1, 
    bytes calldata _data
  ) external {
    address[] memory path = new address[](2); // They are two: from_token and to_token
    uint amountToken = _amount0 == 0 ? _amount1 : _amount0;
    
    address token0 = IUniswapV2Pair(msg.sender).token0();
    address token1 = IUniswapV2Pair(msg.sender).token1();

    require(
      msg.sender == UniswapV2Library.pairFor(pancakeFactory, token0, token1), 
      'Unauthorized'
    ); 
    require(_amount0 == 0 || _amount1 == 0);

    path[0] = _amount0 == 0 ? token1 : token0;
    path[1] = _amount0 == 0 ? token0 : token1;

    IERC20 token = IERC20(_amount0 == 0 ? token1 : token0);
    
    token.approve(address(bakeryRouter), amountToken);

    // Swap and make arbitrage
    uint amountRequired = UniswapV2Library.getAmountsIn(
      pancakeFactory, 
      amountToken, 
      path
    )[0];

    // Get the amount of the loan we took
    uint amountReceived = bakeryRouter.swapExactTokensForTokens(
      amountToken, 
      amountRequired, 
      path, 
      msg.sender, 
      deadline
    )[1];

    IERC20 otherToken = IERC20(_amount0 == 0 ? token0 : token1);
    // Payback the loan
    otherToken.transfer(msg.sender, amountRequired);
    // Transfer profits on our wallet
    otherToken.transfer(tx.origin, amountReceived - amountRequired);
  }
}
