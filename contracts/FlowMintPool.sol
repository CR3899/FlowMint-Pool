// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title FlowMint Pool
 * @dev A decentralized liquidity pool with token minting and staking capabilities
 */
contract FlowMintPool {
    
    // State variables
    address public owner;
    uint256 public totalLiquidity;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public minimumStake;
    bool public poolActive;
    
    // Mappings
    mapping(address => uint256) public liquidityBalance;
    mapping(address => uint256) public stakedAmount;
    mapping(address => uint256) public rewards;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public lastStakeTime;
    
    // Events
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event PoolStatusChanged(bool status);
    event TokensMinted(address indexed recipient, uint256 amount);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier poolIsActive() {
        require(poolActive, "Pool is not active");
        _;
    }
    
    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = block.timestamp;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }
    
    constructor(uint256 _rewardRate, uint256 _minimumStake) {
        owner = msg.sender;
        rewardRate = _rewardRate;
        minimumStake = _minimumStake;
        poolActive = true;
        lastUpdateTime = block.timestamp;
    }
    
    /**
     * @dev Function 1: Add liquidity to the pool
     */
    function addLiquidity() external payable poolIsActive {
        require(msg.value > 0, "Must send ETH to add liquidity");
        
        liquidityBalance[msg.sender] += msg.value;
        totalLiquidity += msg.value;
        
        emit LiquidityAdded(msg.sender, msg.value);
    }
    
    /**
     * @dev Function 2: Remove liquidity from the pool
     */
    function removeLiquidity(uint256 amount) external poolIsActive {
        require(liquidityBalance[msg.sender] >= amount, "Insufficient liquidity balance");
        require(address(this).balance >= amount, "Insufficient pool balance");
        
        liquidityBalance[msg.sender] -= amount;
        totalLiquidity -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit LiquidityRemoved(msg.sender, amount);
    }
    
    /**
     * @dev Function 3: Stake tokens in the pool
     */
    function stake() external payable poolIsActive updateReward(msg.sender) {
        require(msg.value >= minimumStake, "Amount below minimum stake");
        
        stakedAmount[msg.sender] += msg.value;
        lastStakeTime[msg.sender] = block.timestamp;
        
        emit Staked(msg.sender, msg.value);
    }
    
    /**
     * @dev Function 4: Unstake tokens from the pool
     */
    function unstake(uint256 amount) external updateReward(msg.sender) {
        require(stakedAmount[msg.sender] >= amount, "Insufficient staked amount");
        require(block.timestamp >= lastStakeTime[msg.sender] + 1 days, "Minimum stake period not met");
        
        stakedAmount[msg.sender] -= amount;
        
        payable(msg.sender).transfer(amount);
        
        emit Unstaked(msg.sender, amount);
    }
    
    /**
     * @dev Function 5: Claim rewards
     */
    function claimRewards() external updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        
        rewards[msg.sender] = 0;
        
        payable(msg.sender).transfer(reward);
        
        emit RewardClaimed(msg.sender, reward);
    }
    
    /**
     * @dev Function 6: Calculate reward per token
     */
    function rewardPerToken() public view returns (uint256) {
        if (totalLiquidity == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored + (((block.timestamp - lastUpdateTime) * rewardRate * 1e18) / totalLiquidity);
    }
    
    /**
     * @dev Function 7: Calculate earned rewards for an account
     */
    function earned(address account) public view returns (uint256) {
        return ((stakedAmount[account] * (rewardPerToken() - userRewardPerTokenPaid[account])) / 1e18) + rewards[account];
    }
    
    /**
     * @dev Function 8: Update reward rate (owner only)
     */
    function updateRewardRate(uint256 newRate) external onlyOwner updateReward(address(0)) {
        rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    /**
     * @dev Function 9: Toggle pool status (owner only)
     */
    function togglePoolStatus() external onlyOwner {
        poolActive = !poolActive;
        emit PoolStatusChanged(poolActive);
    }
    
    /**
     * @dev Function 10: Mint tokens to an address (owner only)
     */
    function mintTokens(address recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Invalid recipient address");
        require(amount > 0, "Amount must be greater than 0");
        
        payable(recipient).transfer(amount);
        
        emit TokensMinted(recipient, amount);
    }
    
    // View functions
    function getPoolBalance() external view returns (uint256) {
        return address(this).balance;
    }
    
    function getUserLiquidity(address user) external view returns (uint256) {
        return liquidityBalance[user];
    }
    
    function getUserStake(address user) external view returns (uint256) {
        return stakedAmount[user];
    }
    
    function getUserRewards(address user) external view returns (uint256) {
        return earned(user);
    }
    
    // Fallback function to receive ETH
    receive() external payable {
        totalLiquidity += msg.value;
        emit LiquidityAdded(msg.sender, msg.value);
    }
}