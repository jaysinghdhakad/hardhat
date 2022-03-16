const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Test for market place", function(){
  it("should pass all the test", async function(){
    const [owner , account1 , account2, account3] = await ethers.getSigners();

    // deployoing erc-20 contract to be used as token for testing
    const WETH = await ethers.getContractFactory("MyToken");
    const  weth = await WETH.deploy("WETH" , "W");
    await weth.deployed();
 

    //deploy ERC-721 token for the sale 
    const NFTtoken = await ethers.getContractFactory("my721",account1)
    const nftToken = await NFTtoken.deploy("jay", "J");
    await nftToken.deployed();
    
    //check if the nftToken is corretly deployed 
    expect(await nftToken.name()).to.eq("jay");

    //deploy market place contract 
    const Market = await  ethers.getContractFactory("MarketPlace",account2);
    const marketPlace = await Market.deploy(55,10000, weth.address);
    await marketPlace.deployed();

    //check if market place is correctly deployed
    expect(await marketPlace.feeRateNumerator()).to.eq(55);
    
    //check the owner of the id 2 nft 
    expect(await nftToken.ownerOf(2)).to.eq(account1.address);

    // check the owner for id 3 nft 
    expect(await nftToken.ownerOf(3)).to.eq(account1.address);
    
    // approval for market place to tranfer WETH in token swap in market pllace
    const erc20approval = await weth.approve(marketPlace.address,100000000000 );
    await erc20approval.wait();

    // check if the allowance of WETH to market place is correct
    expect(await weth.allowance(owner.address,marketPlace.address)).to.eq(100000000000)

    // approval to Market place to swap NFt id 2
    const erc721Approval1 = await nftToken.approve(marketPlace.address,2);
    await erc721Approval1.wait();
     
    // approval to Market place to swap NFt id 3
    const erc721Approval2 = await nftToken.approve(marketPlace.address,3);
    await erc721Approval2.wait();
    
    //check if the approval are given to market place 
    expect(await nftToken.getApproved(2)).to.eq(marketPlace.address);
    expect(await nftToken.getApproved(3)).to.eq(marketPlace.address);

    //setup sale for id 2 nft at 1 token price 
    const setERC721sale = await marketPlace.connect(account1).setERC721TokenSale(nftToken.address, 2 , 1 , ethers.constants.AddressZero);
    await setERC721sale.wait();
 
    //buy nft from market place 
    const buyERC721AssetWETH = await marketPlace.getERC721AssetWETH(owner.address);
    await buyERC721AssetWETH.wait();
    
    //check if the sale was success full and nft is tranferd to owner
    expect(await nftToken.ownerOf(2)).to.eq(owner.address);

    // reset the sale for new nft of id 3
    const setERC721sale2 = await marketPlace.connect(account1).setERC721TokenSale(nftToken.address, 3 , 1 , ethers.constants.AddressZero);
    await setERC721sale2.wait();
   
    // buy the new nft with ethers 
    const buyERC721AssetETH = await marketPlace.getERC721AssetETH(owner.address, {value: "10000000000000000000"});
    await buyERC721AssetETH.wait();

    //check if the nft id 3 is correctly sold to owner   
    expect(await nftToken.ownerOf(3)).to.eq(owner.address);

    //deploy contract for ERC-1155 tokens with id 1
    const contract1155 = await ethers.getContractFactory("My1155", account3);
    const token1155 = await contract1155.deploy("some");
    await token1155.deployed();

    //give approval to market place to sell tokens  
    const erc1155Approval = await token1155.connect(account3).setApprovalForAll(marketPlace.address,true);
    await erc1155Approval.wait();

    // set the sale for ERC-1155 token on market place 
    const setERC1155Sale = await marketPlace.connect(account3).setERC1155TokenSale(token1155.address, 1, 5, 1, ethers.constants.AddressZero);
    await setERC1155Sale.wait();

    // buy ERC-1155 toke id 1 quantity 2 with WETH
    const buyERC1155AssetWETH = await marketPlace.getERC1155AssetWETH(2, owner.address);
    await buyERC1155AssetWETH.wait();

    // buy ERC-1155 token with id 1 quanity 2 with ETH
    const buyERC1155AssetETH = await marketPlace.getERC1155AssetETH(2, owner.address, {value: "10000000000000000000"});
    await buyERC1155AssetETH.wait();

    // check if the sale of ERC-1155 token went well 
    expect(await token1155.balanceOf(owner.address,1)).to.eq(4);

  });
});

