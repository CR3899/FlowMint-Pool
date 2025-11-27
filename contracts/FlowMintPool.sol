// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title FlowMint Pool
 * @notice A liquidity pool that allows users to deposit ERC20 tokens and mint FlowMint stable/synthetic tokens
 *         - Deposit collateral
 *         - Mint FlowMint token based on pool share
 *         - Withdraw collateral
 *         - Multi-token support
 */

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract FlowMintPool {
    address public owner;
    IERC20 public flowMintToken;

    struct CollateralToken {
        IERC20 token;
        uint256 totalDeposited;
    }

    CollateralToken[] public collaterals;

    mapping(address => mapping(uint256 => uint256)) public userDeposits; // user => collateralIndex => amount
    mapping(address => uint256) public userMinted; // FlowMint tokens minted by user

    event CollateralAdded(address token);
    event Deposited(address indexed user, address token, uint256 amount);
    event Minted(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, address token, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _flowMintToken) {
        owner = msg.sender;
        flowMintToken = IERC20(_flowMintToken);
    }

    // ------------------------------------------------
    // COLLATERAL MANAGEMENT
    // ------------------------------------------------
    function addCollateral(address token) external onlyOwner {
        collaterals.push(CollateralToken({
            token: IERC20(token),
            totalDeposited: 0
        }));
        emit CollateralAdded(token);
    }

    function getCollateralCount() external view returns (uint256) {
        return collaterals.length;
    }

    // ------------------------------------------------
    // USER FUNCTIONS
    // ------------------------------------------------
    function deposit(uint256 collateralIndex, uint256 amount) external {
        require(collateralIndex < collaterals.length, "Invalid index");
        require(amount > 0, "Zero deposit");

        CollateralToken storage c = collaterals[collateralIndex];
        c.token.transferFrom(msg.sender, address(this), amount);
        c.totalDeposited += amount;
        userDeposits[msg.sender][collateralIndex] += amount;

        emit Deposited(msg.sender, address(c.token), amount);
    }

    function mintFlowMint(uint256 amount) external {
        require(amount > 0, "Zero mint");
        // Simple proportional minting: require user has enough collateral
        uint256 totalCollateral = _userTotalCollateral(msg.sender);
        require(totalCollateral >= amount, "Insufficient collateral");

        userMinted[msg.sender] += amount;
        flowMintToken.transfer(msg.sender, amount);

        emit Minted(msg.sender, amount);
    }

    function withdraw(uint256 collateralIndex, uint256 amount) external {
        require(collateralIndex < collaterals.length, "Invalid index");
        require(amount > 0, "Zero withdraw");
        require(userDeposits[msg.sender][collateralIndex] >= amount, "Not enough deposited");

        CollateralToken storage c = collaterals[collateralIndex];
        c.totalDeposited -= amount;
        userDeposits[msg.sender][collateralIndex] -= amount;

        c.token.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, address(c.token), amount);
    }

    // ------------------------------------------------
    // INTERNAL HELPERS
    // ------------------------------------------------
    function _userTotalCollateral(address user) internal view returns (uint256 total) {
        for (uint256 i = 0; i < collaterals.length; i++) {
            total += userDeposits[user][i];
        }
    }

    // ------------------------------------------------
    // ADMIN
    // ------------------------------------------------
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
