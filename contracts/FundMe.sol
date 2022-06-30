// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "./PriceConverter.sol";

error FundMe__NotOwner();

/**
 *   @title A contract for crowdfunding
 *   @author Patrick Collins
 *   @notice This is a demo contract
 *   @dev This implements price feeds as our library
 */

contract FundMe {
    // Type Declarations
    using PriceConverter for uint256;

    // State Variables
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 1 * 1e18; //
    uint256 public EUR = 10;
    uint256 private s_amountInDollar;
    uint256 private s_amountInEuro;

    AggregatorV3Interface private s_ethUsdPriceFeed;
    AggregatorV3Interface private s_eurUsdPriceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "Sender is not owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    constructor(address ethUsdPriceFeedAddress, address eurUsdPriceFeedAddress)
    {
        i_owner = msg.sender;
        s_ethUsdPriceFeed = AggregatorV3Interface(ethUsdPriceFeedAddress);
        s_eurUsdPriceFeed = AggregatorV3Interface(eurUsdPriceFeedAddress);
    }

    function fund() public payable {
        // require value to be at least 1ETH
        require(
            msg.value.getConversionRate(s_ethUsdPriceFeed) > MINIMUM_USD,
            "Didn't send enough!"
        );
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function getEuroPrice() public view returns (uint256) {
        return EUR;
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            //code
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the array
        s_funders = new address[](0);

        // actually withdraw funds - there are three ways

        // transfer
        // payable(msg.sender) = payable address
        //payable(msg.sender).transfer(address(this).balance);

        // send (will only revert with require statement)
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Send failed");

        // call
        (bool callSuccess, ) = i_owner.call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        // the above array once written to memory is MUCH cheaper!
        // mappings can't be in memory!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            //code
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success, "Call failed");
    }

    // View / Pure Functions

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getEthUsdPriceFeed() public view returns (AggregatorV3Interface) {
        return s_ethUsdPriceFeed;
    }

    function getEurUsdPriceFeed() public view returns (AggregatorV3Interface) {
        return s_eurUsdPriceFeed;
    }
}
