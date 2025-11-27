user => collateralIndex => amount
    mapping(address => uint256) public userMinted; ------------------------------------------------
    ------------------------------------------------
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

    USER FUNCTIONS
    Simple proportional minting: require user has enough collateral
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

    INTERNAL HELPERS
    ------------------------------------------------
    ------------------------------------------------
    function transferOwnership(address newOwner) external onlyOwner {
        owner = newOwner;
    }
}
// 
End
// 
