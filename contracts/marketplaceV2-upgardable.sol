// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "hardhat/console.sol";

/*
 * @title MarketPlace to sell ERC1155 and ERC721 tokens
 * @author Jay singh dhakd
 * @notice this contract allows user to sell there tokens with ERC20 token of there choice or WETh and ETh
 * @custom:experimental This is an experimental contract.
 */
contract MarketPlaceup2 {
    address ownerMarketPlace;
    address public contractERC1155;
    uint256 public assetIDERC1155;
    uint256 public assetQuantityERC1155;
    uint256 public assetPriceERC1155;
    address public paymentTokenERC1155;
    address ownerERC1155;
    address tokenWETH;
    uint256 public feeRateNumerator;
    uint256 public feeRateDenominator;
    address public contractERC721;
    uint256 public assetIDERC721;
    uint256 public assetPriceERC721;
    address ownerERC721;
    address public paymentTokenERC721;
    bool isERC721AssetSold;
    uint256 private _NOT_ENTERED;
    uint256 private _ENTERED;
    uint256 private _status;
    bool private initiliazed;
    mapping(uint256 => mapping(address => uint256)) saleRecords;
    string name;

    event TokenTransferERC1155(
        address indexed from,
        address indexed to,
        uint256 tokenID,
        uint256 amount
    );
    event TokenTransferERC721(
        address indexed from,
        address indexed to,
        uint256 tokenID
    );

    /*
     * @notice checks if the contract is initialized or not
     */
    modifier _initializer() {
        require(!initiliazed, "_initializer: contract already initialized");
        _;
    }

    /*
     * @notice checks if quantity asked is less then remaining quantity of ERC1155 assest
     * @params Quantity to compare with
     */
    modifier _CheckQuantity(uint256 quantity) {
        require(
            quantity <= assetQuantityERC1155,
            " _checkQuantity: assets number are less than the required purchasing quatity"
        );
        _;
    }

    /*
     * @notice checks if the ERC721 asset is sold or not
     */
    modifier _checkAvailability() {
        require(
            !isERC721AssetSold,
            "_checkAvailability: ERC721 token already sold"
        );
        _;
    }

    /*
     * @notice prevents reentrancy attacks
     */
    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }

    /*
     * @notice provides initial parameters of feeRateNumerator and feeRateDenominator which can be used to create fee rate for Market place in any percent and     gives the address of
     * WETH token address
     * @params _feeRateNumerator - numerator of fee rate
     * @params _feeRateDenominator- denominator (should be a multiple of 10 and greater than 100)
     * @params _tokenWETH - address of WETH token
     */
    function initialize(
        uint256 _feeRateNumerator,
        uint256 _feeRateDenominator,
        address _tokenWETH,
        string memory _name
    ) external _initializer {
        ownerMarketPlace = msg.sender;
        feeRateNumerator = _feeRateNumerator;
        feeRateDenominator = _feeRateDenominator;
        tokenWETH = _tokenWETH;
        _NOT_ENTERED = 1;
        _ENTERED = 2;
        name = _name;
    }

    /*
     * @notice sets the sale for ERC1155 token
     * @params _contractERC1155 - address of ERC1155 token
     * @params _assetIDERC1155 - id of the token
     * @params _assetQuantityERC1155 - quantity of the token
     * @params _assetPriceERC1155 - price for an asset
     * @arams _paymentTokenERC1155 - address for the paymenttoken you want to use
     */
    function setERC1155TokenSale(
        address _contractERC1155,
        uint256 _assetIDERC1155,
        uint256 _assetQuantityERC1155,
        uint256 _assetPriceERC1155,
        address _paymentTokenERC1155
    ) external {
        contractERC1155 = _contractERC1155;
        assetIDERC1155 = _assetIDERC1155;
        assetQuantityERC1155 = _assetQuantityERC1155;
        assetPriceERC1155 = _assetPriceERC1155;
        paymentTokenERC1155 = _paymentTokenERC1155;
        ownerERC1155 = msg.sender;
    }

    /*
     * @notice sets the sale for ERC721 token
     * @params _contractERC721 - address of ERC721 token
     * @params _assetIDERC721 - id of the token
     * @params _assetPriceERC721 - price for an asset
     * @arams _paymentTokenERC721 - address for the paymenttoken you want to use
     */
    function setERC721TokenSale(
        address _contractERC721,
        uint256 _assetIDERC721,
        uint256 _assetPriceERC721,
        address _paymentTokenERC721
    ) external {
        contractERC721 = _contractERC721;
        assetIDERC721 = _assetIDERC721;
        assetPriceERC721 = _assetPriceERC721;
        paymentTokenERC721 = _paymentTokenERC721;
        ownerERC721 = msg.sender;
        isERC721AssetSold = false;
    }

    /*
     * @notice function to buy ERC1155 asset with owner specified token
     * @params quantity of the asset
     * @params address of the purchaser
     */
    function getERC1155AssetToken(uint256 quantity, address purchaser)
        external
        _CheckQuantity(quantity)
    {
        require(
            paymentTokenERC1155 != address(0),
            "getERC1155AssetToken: user getERC1155AssetWETH or getERC1155AssetETH to buy ERC1155Asset"
        );
        IERC20 paymentToken = IERC20(paymentTokenERC1155);
        _checkAllowance(
            paymentToken,
            purchaser,
            _getCost(quantity, assetPriceERC1155)
        );
        _cutMarketPlacefee(
            paymentToken,
            _getCost(quantity, assetPriceERC1155),
            purchaser
        );
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC1155,
            (_getCost(quantity, assetPriceERC1155) *
                (feeRateDenominator - feeRateNumerator))
        );
        require(sent, "getERC1155AssetToken : tokenTransfer failed");
        _tranferERC1155Asset(assetIDERC1155, quantity, purchaser);
        saleRecords[assetIDERC1155][purchaser] += quantity;
        assetQuantityERC1155 = assetQuantityERC1155 - quantity;
        emit TokenTransferERC1155(
            ownerERC1155,
            purchaser,
            assetIDERC1155,
            quantity
        );
    }

    /*
     * @notice function to buy ERC721 asset with owner specified token
     * @params address of the purchaser
     */
    function getERC721AssetToken(address purchaser)
        external
        _checkAvailability
    {
        require(
            paymentTokenERC721 != address(0),
            "getERC721AssetToken: user getERC721AssetWETH or getERC721AssetETH to buy ERC721Asset"
        );
        IERC20 paymentToken = IERC20(paymentTokenERC721);
        _checkAllowance(paymentToken, purchaser, assetPriceERC721);
        _cutMarketPlacefee(paymentToken, assetPriceERC721, purchaser);
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC721,
            assetPriceERC721 * (feeRateDenominator - feeRateNumerator)
        );
        require(sent, "getERC721AssetToken : tokenTransfer failed");
        _tranferERC721Asset(ownerERC721, purchaser, assetIDERC721);
        saleRecords[assetIDERC1155][purchaser] = 1;
        isERC721AssetSold = true;
        emit TokenTransferERC721(ownerERC721, purchaser, assetIDERC721);
    }

    /*
     * @notice function to buy ERC1155 asset with WETH
     * @params quantity of the asset
     * @params address of the purchaser
     */
    function getERC1155AssetWETH(uint256 quantity, address purchaser)
        external
        _CheckQuantity(quantity)
    {
        require(
            paymentTokenERC1155 == address(0),
            "getERC1155AssetWETH: use getERC1155AssetToken to buy ERC1155Asset"
        );
        IERC20 paymentToken = IERC20(tokenWETH);
        _checkAllowance(
            paymentToken,
            purchaser,
            _getCost(quantity, assetPriceERC1155)
        );
        _cutMarketPlacefee(
            paymentToken,
            _getCost(quantity, assetPriceERC1155),
            purchaser
        );
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC1155,
            (_getCost(quantity, assetPriceERC1155) *
                (feeRateDenominator - feeRateNumerator))
        );
        require(sent, "getERC1155AssetWETH : tokenTransfer failed");
        _tranferERC1155Asset(assetIDERC1155, quantity, purchaser);
        saleRecords[assetIDERC1155][purchaser] += quantity;
        assetQuantityERC1155 = assetQuantityERC1155 - quantity;
        emit TokenTransferERC1155(
            ownerERC1155,
            purchaser,
            assetIDERC1155,
            quantity
        );
    }

    /*
     * @notice function to buy ERC721 asset with WETH
     * @params address of the purchaser
     */
    function getERC721AssetWETH(address purchaser) external _checkAvailability {
        require(
            paymentTokenERC721 == address(0),
            "getERC721AssetWETH: use getERC7215AssetToken to buy ERC721Asset"
        );
        IERC20 paymentToken = IERC20(tokenWETH);
        _checkAllowance(paymentToken, purchaser, assetPriceERC721);
        _cutMarketPlacefee(paymentToken, assetPriceERC721, purchaser);
        bool sent = paymentToken.transferFrom(
            purchaser,
            ownerERC721,
            assetPriceERC721 * (feeRateDenominator - feeRateNumerator)
        );
        require(sent, "getERC721AssetToken : tokenTransfer failed");
        _tranferERC721Asset(ownerERC721, purchaser, assetIDERC721);
        saleRecords[assetIDERC1155][purchaser] = 1;
        isERC721AssetSold = true;
        emit TokenTransferERC721(ownerERC721, purchaser, assetIDERC721);
    }

    /*
     * @notice function to buy ERC1155 asset with ethers
     * @params quantity of the asset
     * @params address of the purchaser
     */
    function getERC1155AssetETH(uint256 quantity, address purchaser)
        external
        payable
        nonReentrant
        _CheckQuantity(quantity)
    {
        require(
            paymentTokenERC1155 == address(0),
            "getERC1155AssetETH: use getERC1155AssetToken to buy ERC1155Asset"
        );
        require(
            msg.value / 10**18 >= quantity * assetPriceERC1155,
            "getERC1155AssetETH: Ether send less than the required ammount to purchase asset"
        );
        uint256 balance = address(this).balance;
        uint256 fees = ((quantity * assetPriceERC1155) *
            (10**18) *
            feeRateNumerator) / feeRateDenominator;
        uint256 cost = (((quantity * assetPriceERC1155) * (10**18)) *
            (feeRateDenominator - feeRateNumerator)) / feeRateDenominator;
        payable(ownerERC1155).transfer(cost);
        uint256 remainingAmount = msg.value - fees - cost;
        if (remainingAmount > 0) payable(purchaser).transfer(remainingAmount);
        require(
            balance == (address(this).balance + cost + remainingAmount),
            "getERC1155AssetETH: ether tranfer failed"
        );
        _tranferERC1155Asset(assetIDERC1155, quantity, purchaser);
        saleRecords[assetIDERC1155][purchaser] += quantity;
        assetQuantityERC1155 = assetQuantityERC1155 - quantity;
        emit TokenTransferERC1155(
            ownerERC1155,
            purchaser,
            assetIDERC1155,
            quantity
        );
    }

    /*
     * @notice function to buy ERC721 asset with ether
     * @params address of the purchaser
     */
    function getERC721AssetETH(address purchaser)
        external
        payable
        nonReentrant
        _checkAvailability
    {
        require(
            paymentTokenERC721 == address(0),
            "getERC721AssetETH: use getERC7215AssetToken to buy ERC721Asset"
        );
        require(
            msg.value / 10**18 >= assetPriceERC721,
            "getERC721AssetETH: Ether send less than the required ammount to purchase asset"
        );
        uint256 balance = address(this).balance;
        uint256 fees = ((assetPriceERC721 * 10**18) * feeRateNumerator) /
            feeRateDenominator;
        uint256 cost = ((assetPriceERC721 * 10**18) *
            (feeRateDenominator - feeRateNumerator)) / feeRateDenominator;
        payable(ownerERC721).transfer(cost);
        uint256 remainingAmount = msg.value - fees - cost;
        if (remainingAmount > 0) payable(purchaser).transfer(remainingAmount);
        require(
            balance == (address(this).balance + cost + remainingAmount),
            "getERC721AssetETH: ether tranfer failed"
        );
        _tranferERC721Asset(ownerERC721, purchaser, assetIDERC721);
        saleRecords[assetIDERC1155][purchaser] = 1;
        isERC721AssetSold = true;
        emit TokenTransferERC721(ownerERC721, purchaser, assetIDERC721);
    }

    /*
     * @notice tranfers ERC721 asset
     * @params from - address of the owner of asset
     * @params to  - address of the purchaser of he asset
     * @params tokenID - the ID of the asset
     */
    function _tranferERC721Asset(
        address from,
        address to,
        uint256 tokenId
    ) internal {
        IERC721 token = IERC721(contractERC721);
        if (isContract(to)) _checkOnIERC721Receiver(tokenId, to);
        token.transferFrom(from, to, tokenId);
    }

    /*
     * @notice tranfers ERC1155 asset
     * @params purchaser - address of the buyer of asset
     * @params quantity  - the quantity of he asset
     * @params assetID - the ID of the asset
     */
    function _tranferERC1155Asset(
        uint256 assetID,
        uint256 quantity,
        address purchaser
    ) internal {
        IERC1155 token = IERC1155(contractERC1155);
        if (isContract(purchaser))
            _checkIERC1155Receiver(purchaser, assetID, quantity);
        token.safeTransferFrom(ownerERC1155, purchaser, assetID, quantity, "");
    }

    /*
     * @notice checks if the contract address can handle ERC721 token
     * @params purchaser - address of buyer contract
     * @params assetID - the ID of the asset
     */
    function _checkOnIERC721Receiver(uint256 assetID, address purchaser)
        internal
    {
        bool output = IERC721Receiver(purchaser).onERC721Received(
            purchaser,
            ownerERC721,
            assetID,
            ""
        ) == IERC721Receiver.onERC721Received.selector;
        if (!output)
            revert("_checkOnIERC721Receiver : contract not a ERC721 reciver ");
    }

    /*
     * @notice checks if the contract address can handle ERC721 token
     * @params purchaser - address of buyer contract
     * @params assetID - the ID of the asset
     */
    function _checkIERC1155Receiver(
        address purchaser,
        uint256 assetID,
        uint256 quantity
    ) internal {
        bool output = IERC1155Receiver(purchaser).onERC1155Received(
            purchaser,
            ownerERC1155,
            assetID,
            quantity,
            ""
        ) == IERC1155Receiver.onERC1155Received.selector;
        if (!output)
            revert("_checkIERC1155Receiver : contract not a ERC721 reciver ");
    }

    /*
     * @notice cuts the market fee in case of token swap transaction
     * @params purchaser - address of buyer contract
     * @params token - the token which is swaped for Asset
     * @param cost - the cost of asset in given token
     */
    function _cutMarketPlacefee(
        IERC20 token,
        uint256 cost,
        address purchaser
    ) internal {
        bool sent = token.transferFrom(
            purchaser,
            ownerMarketPlace,
            (cost * feeRateNumerator)
        );
        require(sent, " _cutMarketPlacefee: tokenTransfer failed");
    }

    /*
     * @notice checks for the allowance in the given token to swap
     * @params purchaser - address of buyer contract
     * @params token - the token which is swaped for Asset
     * @param cost - the cost of asset in given token
     */
    function _checkAllowance(
        IERC20 token,
        address purchaser,
        uint256 cost
    ) internal view {
        require(
            token.allowance(purchaser, address(this)) >= cost,
            "_checkAllowance : spending allowance less than amount"
        );
    }

    /*
     * @notice get the cost in given token to swap for asset
     * @params amount - the quantity of asset to be baught
     * @params tokenPurchasePrice - price in token per asset
     */
    function _getCost(uint256 amount, uint256 tokenPurchasePrice)
        internal
        pure
        returns (uint256)
    {
        return (amount * tokenPurchasePrice);
    }

    /*
     * @notice checks if the address given is that of a contract
     * @params address to be checked
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /*
     *@notcie withDraws ether to the market place owners account
     */
    function withDrawal() external {
        require(
            ownerMarketPlace == msg.sender,
            "withDrawal: not Authorised to withdraw ethers"
        );
        payable(msg.sender).transfer(address(this).balance);
    }

    /*
     * @notice gets the name of the owner
     */
    function getName() external view returns (string memory) {
        return name;
    }
}
