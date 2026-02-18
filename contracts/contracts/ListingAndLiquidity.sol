// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniswapV2Router02 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
}

contract ListingAndLiquidity {
    using SafeERC20 for IERC20;

    address public immutable usdt;
    address public immutable xyz;
    address public immutable router;

    uint256 public listingFee; // USDT smallest unit
    address public owner;

    struct Listing {
        address token;
        address lister;
        uint256 paidAt;
        bool feePaid;
        bool liquidityCreated;
    }

    mapping(address => Listing) public listings;

    event ListingFeePaid(address indexed token, address indexed lister, uint256 fee);
    event LiquidityCreated(address indexed token, address indexed lister, uint amountToken, uint amountXYZ, uint liquidity);

    modifier onlyOwner() {
        require(msg.sender == owner, "NOT_OWNER");
        _;
    }

    constructor(address _usdt, address _xyz, address _router, uint256 _listingFee) {
        require(_usdt != address(0) && _xyz != address(0) && _router != address(0), "ZERO_ADDR");
        usdt = _usdt;
        xyz = _xyz;
        router = _router;
        listingFee = _listingFee;
        owner = msg.sender;
    }

    function setListingFee(uint256 newFee) external onlyOwner {
        listingFee = newFee;
    }

    function getListing(address token) external view returns (Listing memory) {
        return listings[token];
    }

    function payListingFee(address token) external {
        require(token != address(0), "TOKEN_ZERO");
        Listing storage L = listings[token];
        require(!L.feePaid, "ALREADY_PAID");

        // extra friendly checks
        require(IERC20(usdt).balanceOf(msg.sender) >= listingFee, "INSUFFICIENT_USDT");
        require(IERC20(usdt).allowance(msg.sender, address(this)) >= listingFee, "USDT_ALLOWANCE_LOW");

        IERC20(usdt).safeTransferFrom(msg.sender, address(this), listingFee);

        L.token = token;
        L.lister = msg.sender;
        L.paidAt = block.timestamp;
        L.feePaid = true;

        emit ListingFeePaid(token, msg.sender, listingFee);
    }

    function createLiquidity(
        address token,
        uint256 amountTokenDesired,
        uint256 amountXYZDesired,
        uint256 amountTokenMin,
        uint256 amountXYZMin,
        uint256 deadline
    ) external returns (uint amountToken, uint amountXYZ, uint liquidity) {
        require(token != address(0), "TOKEN_ZERO");
        Listing storage L = listings[token];

        require(L.feePaid, "NOT_LISTED_PAY_FEE");
        require(!L.liquidityCreated, "LIQ_ALREADY_CREATED");
        require(msg.sender == L.lister, "ONLY_LISTER");
        require(amountTokenDesired > 0 && amountXYZDesired > 0, "AMOUNT_ZERO");
        require(deadline >= block.timestamp, "DEADLINE_PASSED");

        // clear allowance checks (so revert reason shows)
        require(IERC20(token).allowance(msg.sender, address(this)) >= amountTokenDesired, "TOKEN_ALLOWANCE_LOW");
        require(IERC20(xyz).allowance(msg.sender, address(this)) >= amountXYZDesired, "XYZ_ALLOWANCE_LOW");

        require(IERC20(token).balanceOf(msg.sender) >= amountTokenDesired, "TOKEN_BAL_LOW");
        require(IERC20(xyz).balanceOf(msg.sender) >= amountXYZDesired, "XYZ_BAL_LOW");

        // pull tokens to this contract
        IERC20(token).safeTransferFrom(msg.sender, address(this), amountTokenDesired);
        IERC20(xyz).safeTransferFrom(msg.sender, address(this), amountXYZDesired);

        // approve router (forceApprove handles reset internally)
        IERC20(token).forceApprove(router, amountTokenDesired);
        IERC20(xyz).forceApprove(router, amountXYZDesired);

        (amountToken, amountXYZ, liquidity) = IUniswapV2Router02(router).addLiquidity(
            token,
            xyz,
            amountTokenDesired,
            amountXYZDesired,
            amountTokenMin,
            amountXYZMin,
            msg.sender,
            deadline
        );

        require(liquidity > 0, "LP_ZERO");

        // refund leftovers
        if (amountToken < amountTokenDesired) {
            IERC20(token).safeTransfer(msg.sender, amountTokenDesired - amountToken);
        }
        if (amountXYZ < amountXYZDesired) {
            IERC20(xyz).safeTransfer(msg.sender, amountXYZDesired - amountXYZ);
        }

        L.liquidityCreated = true;

        emit LiquidityCreated(token, msg.sender, amountToken, amountXYZ, liquidity);
    }

    function withdrawFees(address to) external onlyOwner {
        IERC20(usdt).safeTransfer(to, IERC20(usdt).balanceOf(address(this)));
    }
}
