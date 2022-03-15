const { expect } = require("chai");
const { ethers } = require("hardhat");


describe("ERC20", function () {
  it("should pass all the test", async function () {
    const [owner , account1 , account2] = await ethers.getSigners();
    const Mytoken = await ethers.getContractFactory("ERC20Old");
    const mytoken = await Mytoken.deploy()
    await mytoken.deployed();
    
    /*
     * Assertion to get the name from name function 
     */
    expect(await mytoken.name()).to.eq("JToken");
    
    const mintTransaction = await mytoken.mint(100)
    await mintTransaction.wait();

    /*
    * Assertion for both mint and balanceOf function mint fnunction mints 100 token 
    * and if  mint function worked correctly balance of owner should be equal to 100
    */
    expect(await mytoken.balanceOf(owner.address)).to.eq(100);

    const tranferTransaction = await mytoken.transfer( account1.address, 10);
    await tranferTransaction.wait()

    /*
    * Assertion for the transfer function balance of account1 should be equal to 10 
    * as the tranfer of token was carried out above 
    */
    expect(await mytoken.balanceOf(account1.address)).to.eq(10);

    const approeTransaction = await mytoken.approve(account1.address, 10);
    await approeTransaction.wait();

    /*
    * Assertion for both approve and getAllowance function as accout1 was approve 
    * above and that should make it allowance 10 for owner's token  
    */
    expect(await mytoken.getAllowance(owner.address,account1.address)).to.eq(10);

    const tranferfromTransaction = await mytoken.connect(account1).transferfrom(owner.address, account2.address, 10);
    await tranferfromTransaction.wait();

    /*
    * Assertion for tranferfrom function as account1 tranfered owner's 10 token to 
    * account2 account2's ba;ance should be 10 
    */
    expect(await mytoken.balanceOf(account2.address)).to.eq(10);

    /*
    * This assertion should not work as the owner has no allowance for his own coin 
    * in the alowance mapping 
    */
    expect(await mytoken.transferfrom(owner.address, account1.address, 10))
      .to.emit(mytoken, "log")
      .withArgs(owner.address, account1.address, 10);
    
    // console.log(expect(await mytoken.transferfrom(owner.address, account1.address, 10))
    // .to.emit(mytoken, "log")
    // .withArgs(owner.address, account1.address, 10))

  });
});