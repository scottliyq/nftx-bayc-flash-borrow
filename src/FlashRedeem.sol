// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "forge-std/console.sol";
import { INFTXVault } from "nftx/interface/INFTXVault.sol";
import { IERC3156FlashBorrowerUpgradeable, IERC3156FlashLenderUpgradeable } from "nftx/interface/IERC3156Upgradeable.sol";
import { IERC20Upgradeable } from "nftx/token/IERC20Upgradeable.sol";
import { IERC721Upgradeable } from "nftx/token/IERC721Upgradeable.sol";
import { IERC721ReceiverUpgradeable } from "nftx/token/IERC721ReceiverUpgradeable.sol";
import { IUniswapV2Router02 } from "uni/interfaces/IUniswapV2Router02.sol";

interface ApeCoinAirdrop {
    function claimTokens() external;
}

interface DoodlesAirdrop {
    function claim() external;
}

contract FlashRedeem is IERC3156FlashBorrowerUpgradeable, IERC721ReceiverUpgradeable {

    // ============ Private constants ============
    address private DOODLES_NFT_ADDR = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
    address private DOODLES_NFTX_ADDR = 0x2F131C4DAd4Be81683ABb966b4DE05a549144443;
    address private DOODLES_AIRDROP_ADDR = 0x466CFcD0525189b573E794F554b8A751279213Ac;
    address private SUSHI_ROUTER_ADDR = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    address private WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private NFTXVaultUpgradeable = 0x4d6d117Bf2Fd1FfC790B95C219f4FA7e338D3172;
    uint256[] private doodlesTokenArr;

    IERC20Upgradeable private DOODLES_NFTX_TOKEN = IERC20Upgradeable(DOODLES_NFTX_ADDR);
    IERC721Upgradeable private DOODLES_NFT = IERC721Upgradeable(DOODLES_NFT_ADDR);
    IERC721Upgradeable private DOODLES_AIRDROP_TOKEN = IERC721Upgradeable(DOODLES_AIRDROP_ADDR);
    INFTXVault private DOODLES_NFTX_VAULT = INFTXVault(DOODLES_NFTX_ADDR);
    IERC20Upgradeable private WETH_TOKEN = IERC20Upgradeable(WETH_ADDR);
    IERC3156FlashLenderUpgradeable private lender = IERC3156FlashLenderUpgradeable(DOODLES_NFTX_ADDR);
    DoodlesAirdrop private doodlesAirdrop = DoodlesAirdrop(DOODLES_AIRDROP_ADDR);
    IUniswapV2Router02 private sushiRouter = IUniswapV2Router02(SUSHI_ROUTER_ADDR);

    // ============ Constructor ============

    constructor() {}

    // ============ Functions ============

    /// @dev ERC-3156 Flash loan callback
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external override returns(bytes32) {
        require(
            msg.sender == address(lender),
            "FlashBorrower: Untrusted lender"
        );
        require(
            initiator == address(this),
            "FlashBorrower: Untrusted loan initiator"
        );
        console.log("New DOODLES NFTX token balance: ", DOODLES_NFTX_TOKEN.balanceOf(address(this)));

        // Redeem DOODLES NFTX Vault Tokens for DOODLES NFTs.
        uint256[] memory emptySpecificIdsArr;
        DOODLES_NFTX_VAULT.redeem(10, emptySpecificIdsArr);
        console.log("New DOODLES NFT token balance: ", DOODLES_NFT.balanceOf(address(this)));

        // Claim ApeCoin airdrop
        doodlesAirdrop.claim();
        console.log("New Dooplicator balance: ", DOODLES_AIRDROP_TOKEN.balanceOf(address(this)));
        console.log("Repayment doodles length: ", doodlesTokenArr.length);
        // Set approval on DOODLES NFTs and Mint NFTX tokens for flash loan fee repayment. Pay 10% fee (6 NFTs = 0.6 fee) to mint
        DOODLES_NFT.setApprovalForAll(DOODLES_NFTX_ADDR, true);
        for (uint i = 0; i < doodlesTokenArr.length; i ++) {  //for loop example
            console.log("Repayment doodles: ", doodlesTokenArr[i]);
            console.log("Ownerof doodles: ", DOODLES_NFT.ownerOf(doodlesTokenArr[i]));
            console.log("This address: ", address(this));
            console.log("Is approve this : ", DOODLES_NFT.isApprovedForAll(address(this), DOODLES_NFTX_ADDR));

            DOODLES_NFT.approve(DOODLES_NFTX_ADDR, doodlesTokenArr[i]);

            console.log("Repayment doodles: ", DOODLES_NFT.getApproved(doodlesTokenArr[i]));         
        }
        uint256[] memory emptyAmountsArr;
        console.log("Is approve : ", DOODLES_NFT.isApprovedForAll(address(this), DOODLES_NFTX_ADDR));
        DOODLES_NFTX_VAULT.mint(doodlesTokenArr, emptyAmountsArr);
        console.log("Is approve : ", DOODLES_NFT.isApprovedForAll(address(this), DOODLES_NFTX_ADDR));

        // Set approval on NFTX tokens for Sushi, swap extra NFTX tokens for ETH
        // SushiSwap (DOODLES-NFTX -> WETH) path
        address[] memory path = new address[](2);
        path[0] = DOODLES_NFTX_ADDR;
        path[1] = sushiRouter.WETH();

        
        uint256 excessDoodlesNftxTokens = DOODLES_NFTX_TOKEN.balanceOf(address(this)) - amount;
        console.log("excessDoodlesNftxTokens: ", excessDoodlesNftxTokens);
        if(excessDoodlesNftxTokens != 0){
            console.log("ETH balance before swap: ", address(this).balance);
            DOODLES_NFTX_TOKEN.approve(SUSHI_ROUTER_ADDR, excessDoodlesNftxTokens);
            sushiRouter.swapExactTokensForETH(excessDoodlesNftxTokens, 0, path, address(this), block.timestamp);
            console.log("ETH balance after swap: ", address(this).balance);
        }
        return keccak256("ERC3156FlashBorrower.onFlashLoan");
    }

    /// @dev Initiate a flash loan
    function flashBorrow(
        address token,
        uint256 amount
    ) public payable {
        address[] memory path = new address[](2);
        path[0] = sushiRouter.WETH();
        path[1] = DOODLES_NFTX_ADDR;

        console.log("NFTX balance before swap: ", IERC20Upgradeable(token).balanceOf(address(this)));
        sushiRouter.swapETHForExactTokens{value: msg.value}(500000000000000000, path, address(this), block.timestamp);
        console.log("NFTX balance after swap: ", IERC20Upgradeable(token).balanceOf(address(this)));

        uint256 _allowance = IERC20Upgradeable(token).allowance(address(this), address(lender));
        uint256 _fee = lender.flashFee(token, amount);
        uint256 _repayment = amount + _fee;
        IERC20Upgradeable(token).approve(address(lender), _allowance + _repayment);
        console.log("amount+fee",  _allowance + _repayment);
        console.log("balance of",  IERC20Upgradeable(token).balanceOf(address(this)));
        lender.flashLoan(this, token, amount, new bytes(0));
    }

    // Make contract payable to receive funds
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4) {
        if(from == DOODLES_NFTX_ADDR){
            doodlesTokenArr.push(tokenId);
            console.log("Repayment doodles tokenId: ", tokenId, from);
        }
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")); // IERC721Receiver.onERC721Received.selector
    }

}