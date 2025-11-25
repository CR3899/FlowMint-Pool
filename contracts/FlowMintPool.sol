State variables
    address public owner;
    uint256 public totalLiquidity;
    uint256 public rewardRate;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    uint256 public minimumStake;
    bool public poolActive;
    
    Events
    event LiquidityAdded(address indexed provider, uint256 amount);
    event LiquidityRemoved(address indexed provider, uint256 amount);
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event RewardRateUpdated(uint256 newRate);
    event PoolStatusChanged(bool status);
    event TokensMinted(address indexed recipient, uint256 amount);
    
    View functions
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
    
    End
// 
// 
End
// 
