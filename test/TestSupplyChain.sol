pragma solidity ^0.4.23;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/SupplyChain.sol";

contract TestSupplyChain {
    uint public initialBalance = 15 ether;

    function () public payable {}

    // Test for failing conditions in this contracts
    
    // test that every modifier is working
    function testContractOwner() public {
        SupplyChain supplyContract = new SupplyChain();
        Assert.equal(supplyContract.owner(), this, "An owner is different than a deployer");
    }

    //Test for Adding an Item to the existing deployed Contract Addresses
    function testAddItemInAlreadyDeployedContract() public{
        SupplyChain supplyContract = SupplyChain(DeployedAddresses.SupplyChain());
        bool result = supplyContract.addItem("book2", 1); 
        Assert.isTrue(result, "Item should be added in the Contract");
    }

    //Without using Deployed Address we can use new address for every storage (Like creating new instance)
    function testAddItemInNewContract() public{
        SupplyChain supplyContract = new SupplyChain();
        bool result = supplyContract.addItem("book2", 2); 
        Assert.isTrue(result, "Item should be added in the Contract");
    }


    // buyItem

    //Test Buy Item Function is successful
    function testBuytItem() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("test1", 1 ether);  //Funds Storage
        supplyContract.buyItem.value(2 ether)(0);             //Buy Item by passing less than the ether of actual item (0 - is the index for current Item that is added)
        
        string memory name = "";
        uint sku; 
        uint price; 
        uint state; 
        address seller; 
        address buyer; 
        ( name, sku, price, state, seller, buyer) = supplyContract.fetchItem.gas(200000)(0);

        Assert.equal(name, "test1", "the name of the last added item does not match the expected value");
        Assert.equal(price, 1000000000000000000, 'the price of the last added item does not match the expected value');
        Assert.equal(state, 1, 'the state of the item should be "Sold", which should be declared first in the State Enum');
    }


    // test for failure if user does not send enough funds
    function testBuytItemWithoutFunds() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("t1", 1 ether);  //Funds Storage        
        bool result = address(supplyContract).call.value(0.5 ether)(bytes4(keccak256("buyItem(uint256)")), 0);
        Assert.isFalse(result, "It Should Fail As there is no sufficient funds to Purchase Item");
    }

    // test for purchasing an item that is not for Sale
    function testBuyItemwithNotSale() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("t1", 1 ether);  //Funds Storage        -- Item is For Sale
       
        supplyContract.buyItem.value(2 ether)(0);             //Buy Item by passing less than the ether of actual item (0 - is the index for current Item that is added)  -- Item is SOLD

        bool result = address(supplyContract).call.value(1 ether)(bytes4(keccak256("buyItem(uint256)")), 0);
        Assert.isFalse(result, "It Should Fail as the item that is requesting is not for sale");
    }


    // shipItem

    //Test Ship Item Function is successful
    function testShipItem() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("test1", 1 ether);  //Funds Storage
        supplyContract.buyItem.value(2 ether)(0);             //Buy Item by passing less than the ether of actual item (0 - is the index for current Item that is added)
        
        supplyContract.shipItem(0);   //State is - Shipped

        string memory name = "";
        uint sku; 
        uint price; 
        uint state; 
        address seller; 
        address buyer; 
        ( name, sku, price, state, seller, buyer) = supplyContract.fetchItem.gas(200000)(0);

        Assert.equal(name, "test1", "the name of the last added item does not match the expected value");
        Assert.equal(price, 1000000000000000000, 'the price of the last added item does not match the expected value');
        Assert.equal(state, 2, 'the state of the item should be "Shipped", which should be declared first in the State Enum');
    }


    // test for calls that are made by not the seller
    function testShipItemOtherThanSeller() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("t1", 1 ether);  //Funds Storage (Seller is updated)     - State is (For Sale)   
        
        supplyContract.buyItem.value(2 ether)(0);  //State is - Sold

        SupplyChain supplyContract2 = new SupplyChain();   //Lets suppose the call is happening from third contract address
        bool result = address(supplyContract2).call(bytes4(keccak256("shipItem(uint256)")), 0);

        Assert.isFalse(result, "It Should Fail, as the seller address will differ than the addItem procedure");
    }

    // test for trying to ship an item that is not marked Sold
    function testShipItemStateNotAsSold() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("t1", 1 ether);  //Funds Storage (Seller is updated)     - State is (For Sale)   

        //Now the State of Item is still - For Sale
        bool result = address(supplyContract).call(bytes4(keccak256("shipItem(uint256)")), 0);         //It should fail as the state is not Sold
        
        string memory name = "";
        uint sku; 
        uint price; 
        uint state; 
        address seller; 
        address buyer; 
        
        ( name, sku, price, state, seller, buyer) = supplyContract.fetchItem.gas(200000)(0);
        Assert.equal(name, "t1", "the name of the last added item does not match the expected value");
        Assert.equal(price, 1000000000000000000, 'the price of the last added item does not match the expected value');
        Assert.equal(state, 0, 'the state of the item should be "Sold", which should be declared first in the State Enum');

        Assert.isFalse(result, "It Should Fail, as the seller address will differ than the addItem procedure");
    }

    // receiveItem
    //Test Receive Item Function is successful
    function testReceiveItem() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("test1", 1 ether);  //Funds Storage
        supplyContract.buyItem.value(2 ether)(0);             //Buy Item by passing less than the ether of actual item (0 - is the index for current Item that is added)
        
        supplyContract.shipItem(0);   //State is - Shipped

        supplyContract.receiveItem(0);   //State is - Shipped


        string memory name = "";
        uint sku; 
        uint price; 
        uint state; 
        address seller; 
        address buyer; 
        ( name, sku, price, state, seller, buyer) = supplyContract.fetchItem.gas(200000)(0);

        Assert.equal(name, "test1", "the name of the last added item does not match the expected value");
        Assert.equal(price, 1000000000000000000, 'the price of the last added item does not match the expected value');
        Assert.equal(state, 3, 'the state of the item should be "Shipped", which should be declared first in the State Enum');
    }

    // test calling the function from an address that is not the buyer
    function testReceiveItemOtherThanBuyer() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("t1", 1 ether);  //Funds Storage (Seller is updated)     - State is (For Sale)   
        
        supplyContract.buyItem.value(2 ether)(0);  //State is - Sold

        supplyContract.shipItem(0);   //State is - Shipped

        SupplyChain supplyContract2 = new SupplyChain();   //Lets suppose the call is happening from third contract address
        bool result = address(supplyContract2).call(bytes4(keccak256("receiveItem(uint256)")), 0);

        Assert.isFalse(result, "It Should Fail, as the seller address will differ than the addItem procedure");
    }

    // test calling the function on an item not marked Shipped
    function testReceiveItemNotShipped() public {
        SupplyChain supplyContract = new SupplyChain();
        supplyContract.addItem("t1", 1 ether);  //Funds Storage (Seller is updated)     - State is (For Sale)   
        
        supplyContract.buyItem.value(2 ether)(0);  //State is - Sold

        //Now the Item still in Sold State Hence he call should reject
        bool result = address(supplyContract).call(bytes4(keccak256("receiveItem(uint256)")), 0);

        Assert.isFalse(result, "It Should Fail, as the seller address will differ than the addItem procedure");
    }

}
