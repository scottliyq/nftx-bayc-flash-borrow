// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.10;

import "ds-test/test.sol";
import "forge-std/console.sol";
import "../FlashRedeem.sol";
import { IERC721Upgradeable } from "nftx/token/IERC721Upgradeable.sol";

interface CheatCodes {
    function startPrank(address) external;
    function stopPrank() external;
}

contract FlashRedeemTest is DSTest {

    address private DOODLES_NFTX_ADDR = 0x2F131C4DAd4Be81683ABb966b4DE05a549144443;
    address private DOODLES_NFT_ADDR = 0x8a90CAb2b38dba80c64b7734e58Ee1dB38B8992e;
    address private SENSEI_ADDR = 0x527B0642b3902C3Bc29ae13D8208b86dA007aa26;

    FlashRedeem flashRedeem;
    IERC721Upgradeable private DOODLES_NFT = IERC721Upgradeable(DOODLES_NFT_ADDR);


    function setUp() public {
        flashRedeem = new FlashRedeem();
    }

    function testFlashRedeem() public {
        // 5.2e18 (1e18 is decimal configuration for BAYC Token - flash loan 5.2 tokens)
        // why 5.2? NFTX vault charges 4% redeem fee, 5.2 allows us to redeem exactly 5 NFTs
        uint256 amount =  10400000000000000000;
        address flashRedeemContractAddr = address(flashRedeem);
        console.log("flashRedeemContractAddr", flashRedeemContractAddr);

        CheatCodes cheats = CheatCodes(HEVM_ADDRESS);
        cheats.startPrank(SENSEI_ADDR);

        DOODLES_NFT.setApprovalForAll(flashRedeemContractAddr, true);
        flashRedeem.flashBorrow{value: 8.5 ether}(DOODLES_NFTX_ADDR, amount);

        cheats.stopPrank();
    }
}
