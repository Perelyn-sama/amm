// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AMM {
    using SafeMath for uint256;

    uint totalShares; // Stores the total amount of share issued for the pool
    uint totalToken1; // Stores the amount of Token1 locked in the pool
    uint totalToken2; // Stores the amount of Token2 locked in the pool
    uint K; // Algoritmic constant used to determine price (K = totalToken1 * totalToken2)

    uint constant PRECISION = 1_000_000; // Precisioin of 6 decimal places

    mapping(address => uint) shares; // Stores the share holding of each provider

    mapping(address => uint) token1Balance; // Stores the available balance of user outside of the AMM
    mapping(address => uint) token2Balance;

    // Ensure that the _qty is non-zero and the user has enough balance
    modifier validAmountCheck(mapping(address => uint)storage _balance, uint _qty ) {
        require(_qty > 0, "Amount cannot be zero!");
        require(_qty <= _balance[msg.sender], "Insufficient amount");
        _;
    }

    // Restricts withdraw, swap feature till liquidity is added to the pool
    modifier activePool() {
        require(totalShares > 0 , "Zero Liquidity");
        _;
    }

    // Returns the balance of the user
    function getMyHoldings() external view returns(uint amountToken1, uint amountToken2, uint myShare){
        amountToken1 = token1Balance[msg.sender];
        amountToken2 = token2Balance[msg.sender];
        myShare = shares[msg.sender];
    }

    // Returns the total  amount of tokens in the pool and the total share issued corresponding to it
    function getPoolDetails() external view returns(uint, uint, uint){
        return (totalToken1, totalToken2, totalShares);
    }

    // Sends free tokens to the invoker
    function faucet(uint256 _amountToken1, uint _amountToken2) external {
    token1Balance[msg.sender] = token1Balance[msg.sender].add(_amountToken1);
    token2Balance[msg.sender] = token2Balance[msg.sender].add(_amountToken2);
    }

   
    // Adding new liquidity in the pool
    // Returns the amount of share issued for locking given assets
    function provide(uint256 _amountToken1, uint256 _amountToken2) external validAmountCheck(token1Balance, _amountToken1) validAmountCheck(token2Balance, _amountToken2) returns(uint256 share) {
    if(totalShares == 0) { // Genesis liquidity is issued 100 Shares
        share = 100*PRECISION;
    } else{
        uint256 share1 = totalShares.mul(_amountToken1).div(totalToken1);
        uint256 share2 = totalShares.mul(_amountToken2).div(totalToken2);
        require(share1 == share2, "Equivalent value of tokens not provided...");
        share = share1;
    }

    require(share > 0, "Asset value less than threshold for contribution!");
    token1Balance[msg.sender] -= _amountToken1;
    token2Balance[msg.sender] -= _amountToken2;

    totalToken1 += _amountToken1;
    totalToken2 += _amountToken2;
    K = totalToken1.mul(totalToken2);

    totalShares += share;
    shares[msg.sender] += share;
    }

    // Returns amount of Token1 required when providing liquidity with _amountToken2 quantity of Token2
    function getEquivalentToken1Estimate(uint256 _amountToken2) public view activePool returns(uint256 reqToken1) {
    reqToken1 = totalToken1.mul(_amountToken2).div(totalToken2);
    }

    // Returns amount of Token2 required when providing liquidity with _amountToken1 quantity of Token1
    function getEquivalentToken2Estimate(uint256 _amountToken1) public view activePool returns(uint256 reqToken2) {
    reqToken2 = totalToken2.mul(_amountToken1).div(totalToken1);
    }
}

