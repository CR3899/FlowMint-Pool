// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

/**
 * @title FlowMint Pool
 * @notice A decentralized liquidity pool where users deposit ERC-20 tokens to earn
 *         yield based on a dynamic reward emission rate set by the protocol owner.
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FlowMintPool {
    IERC20 public poolToken;
    address public owner;
    uint256 public rewardRatePerSecond; // 18-decimal precision reward

    struct User {
        uint256 deposited;
        uint256 rewardDebt;
        uint256 lastUpdated;
    }

    mapping(address => User) public users;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 principal, uint256 reward);
    event RewardRateUpdated(uint256 newRate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(address _poolToken, uint256 _rewardRatePerSecond) {
        require(_poolToken != address(0), "Invalid token address");
        poolToken = IERC20(_poolToken);
        rewardRatePerSecond = _rewardRatePerSecond;
        owner = msg.sender;
    }

    // Calculate pending rewards for a user
    function _pendingReward(address user) internal view returns (uint256) {
        User memory u = users[user];
        if (u.deposited == 0) return 0;
        uint256 timeElapsed = block.timestamp - u.lastUpdated;
        return u.deposited * rewardRatePerSecond * timeElapsed / 1e18;
    }

    // Update user's reward tracking
    function _updateRewards(address user) internal {
        if (users[user].deposited > 0) {
            users[user].rewardDebt += _pendingReward(user);
        }
        users[user].lastUpdated = block.timestamp;
    }

    /** Deposit pool tokens to start earning yield */
    function deposit(uint256 amount) external {
        require(amount > 0, "Amount > 0");
        _updateRewards(msg.sender);

        users[msg.sender].deposited += amount;
        poolToken.transferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    /** Withdraw principal + accumulated yield */
    function withdraw(uint256 amount) external {
        require(users[msg.sender].deposited >= amount, "Insufficient deposit");
        _updateRewards(msg.sender);

        uint256 reward = users[msg.sender].rewardDebt;
        users[msg.sender].rewardDebt = 0;
        users[msg.sender].deposited -= amount;

        poolToken.transfer(msg.sender, amount + reward);

        emit Withdrawn(msg.sender, amount, reward);
    }

    /** View pending yield without withdrawing */
    function pendingReward(address user) external view returns (uint256) {
        return users[user].rewardDebt + _pendingReward(user);
    }

    /** Admin sets a new reward emission rate */
    function updateRewardRate(uint256 newRate) external onlyOwner {
        rewardRatePerSecond = newRate;
        emit RewardRateUpdated(newRate);
    }

    /** Emergency withdrawal of pool assets — owner only */
    function emergencyWithdraw(uint256 amount) external onlyOwner {
        poolToken.transfer(owner, amount);
    }

    /** Get user’s deposited liquidity amount */
    function getDeposited(address user) external view returns (uint256) {
        return users[user].deposited;
    }
}
