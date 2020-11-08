pragma solidity >=0.4.22 <=0.8.0;

contract DropDapp {
    
    //Address used to deploy contract
    address admin;
    
    
    //Seller Struct
    struct Seller {
        address sellerId;
        bool isRegistered;
    }

    //Customer struct
    struct Customer {
        address customerId;
        bool isRegistered;
        bytes32 secret;
    }
    
    enum productStatus{Open, Closed, Processed, Terminated} 
    
    enum orderStatus{Placed, Cancelled, Refunded, Shipping}
    
    
    //Product struct
    struct Product {
        bytes32 productId;
        uint256 price;
        uint minCount;
        uint maxCount;
        uint orderCount;
        address payable sellerId; 
        productStatus status;
    }
    
    
    //Order struct
    struct Order {
        bytes32 productId;
        bytes32 orderId;
        bytes32 secret;
        address customerId;
        orderStatus status;
    }
    
    //Mapping to keep track of sellers
    mapping(address => Seller) sellers;
    
    //Mapping to keep track of customers
    mapping(address => Customer) customers;
    
    //Mapping to keep track of product details using productId
    mapping(bytes32 => Product) products;
    
    //Mapping to keep track of placed orders using orderHash
    mapping(bytes32 => Order) placedOrders;
    
    
    //Check if the user is a registered seller
    modifier sellerOnly {
        require(sellers[msg.sender].isRegistered);
        _;
    }
    
    //Check if the user is a registered customer
    modifier customerOnly {
        require(customers[msg.sender].isRegistered);
        _;
    }
    
    //Check if the the newly advertised product is unique
    modifier isUniqueProduct(bytes32 productId) {
        require(products[productId].sellerId == address(0));
        _;
    }
    
    modifier validateAdvertisement(uint256 price, uint minCount, uint maxCount)
    {
        require(price > 0 && minCount > 0 && maxCount > 0);
        _;
    }
    
    modifier validateSeller(bytes32 productId, address sender)
    {
        require(products[productId].sellerId == sender);
        _;
    }
    
    //Check if the Advertisement is still valid
    modifier isOfferValid(bytes32 productId) {
        require(products[productId].status == productStatus.Open);
        _;
    }
    
    //Check if the order made is valid
    modifier isValidOrder(bytes32 orderHash, bytes32 orderSecret) {
        require (placedOrders[orderHash].secret == keccak256(abi.encodePacked(customers[placedOrders[orderHash].customerId].secret, orderSecret)));
        _;
    }

    //Event to notify that the product has been advertised
    event productAdvertised(bytes32, uint256, uint, uint);
    
    //Event to notify the end of an offer
    event orderEnded(productStatus);
    
    
    //Event to notify that the order has been placed and give the orderHash to the customer
    event orderPlaced(bytes32);
    
    //Event to notify the customer that the order has been cancelled
    event orderCancelled(orderStatus);
    
    //Event to notify the customer that the order status has been updated
    event orderUpdated(orderStatus);
    
    //Event to notify the seller that the orders have been processed and that the funds have been transferred to the seller.
    event orderProcessed(productStatus);
    
    
    
    //Make the deployer of the contract the admin
    constructor() public {
        admin = msg.sender;
    }
    
    //Allows users to generate a bytes32 secret using their secret string
    function generateSecret(string memory secret) public pure returns (bytes32 generatedSecret) {
        generatedSecret = keccak256(abi.encodePacked(secret));
        return generatedSecret;
    }
    
    //Register seller
    function registerSeller() public {
        Seller memory seller;
        seller.sellerId = msg.sender;
        seller.isRegistered = true;
        sellers[seller.sellerId] = seller; 
    }
    
    //Resgister customer address and their secret
    function registerCustomer(bytes32 secret) public {
        Customer memory customer;
        customer.customerId = msg.sender;
        customer.isRegistered = true;
        customer.secret = secret;
        customers[customer.customerId] = customer;
        
    } 
    
    //Advertise the product sepecifying productId, price, minimum order count and maximum order count
    function advertiseProduct(bytes32 productId, uint price, uint minCount, uint maxCount) public validateAdvertisement(price, minCount, maxCount) sellerOnly isUniqueProduct(productId) {
        Product memory product;
        product.productId = productId;
        product.price = price*(1 ether);
        product.minCount = minCount;
        product.maxCount = maxCount;
        product.sellerId = msg.sender;
        product.orderCount = 0;
        product.status = productStatus.Open;
        products[productId] = product;
        emit productAdvertised(productId, price, minCount, maxCount);
    }
    
    //Seller ends the offer
    function endOffer(bytes32 productId) public sellerOnly validateSeller(productId, msg.sender) {
        require(products[productId].status == productStatus.Open);
        
        if(products[productId].orderCount >= products[productId].minCount) {
            products[productId].status = productStatus.Closed;
        }
        else
        {
            products[productId].status = productStatus.Terminated;
        }
        emit orderEnded (products[productId].status);
    }
    
    //Customer places order
    function placeOrder(bytes32 productId, bytes32 orderSecret) public payable customerOnly isOfferValid(productId) returns(bytes32) {

        require(products[productId].orderCount + 1 <= products[productId].maxCount);
        require((products[productId].price) <= msg.value);

        Order memory order;
        order.productId = productId;
        order.orderId = keccak256(abi.encodePacked(productId, msg.sender));
        order.secret = keccak256(abi.encodePacked(customers[msg.sender].secret, orderSecret));
        order.customerId = msg.sender;
        order.status = orderStatus.Placed;
        placedOrders[order.orderId] = order;
        products[productId].orderCount += 1;
        emit orderPlaced(order.orderId);
    }
    
    //Customer can withdraw order if the offer is still valid and using the secret 
    function withdrawOrder(bytes32 orderHash, bytes32 orderSecret) isOfferValid(placedOrders[orderHash].productId) isValidOrder(orderHash, orderSecret) public {
        
        require(placedOrders[orderHash].status == orderStatus.Placed);
        refundCustomer(placedOrders[orderHash].productId, orderHash, msg.sender);
        products[placedOrders[orderHash].productId].orderCount -= 1;
        placedOrders[orderHash].status = orderStatus.Cancelled;
        emit orderCancelled(placedOrders[orderHash].status);
    }
    
    //Process customer refunds
    function refundCustomer(bytes32 productId, bytes32 orderHash, address payable customer) internal {
        if (orderHash == keccak256(abi.encodePacked(productId, customer))) 
            customer.transfer(products[productId].price);
    }
    
    /*
        The seller processes the orders based on whether the minimum order count was reached.
        If the minimum order count was reached, the products are shipped, else, the customers who 
        placed orders are refunded.
    */
    function processOrder(bytes32 productId) payable public sellerOnly validateSeller(productId, msg.sender) {
        if(products[productId].status == productStatus.Closed) {
            Product memory product = products[productId];
            uint amount = product.price * product.orderCount;
            product.sellerId.transfer(amount);
            products[productId].status = productStatus.Processed;
            emit orderProcessed(products[productId].status);
        }
    }
    
    /*The customer gets the current status of the order and if the order has been terminated by the seller, gets the amount refunded.
    */
    function orderUpdate(bytes32 orderHash, bytes32 orderSecret) public customerOnly isValidOrder(orderHash, orderSecret) returns (orderStatus) {
        Order memory order = placedOrders[orderHash];
        if (products[order.productId].status == productStatus.Terminated && order.status == orderStatus.Placed) {
            refundCustomer(order.productId, orderHash, msg.sender);
            placedOrders[orderHash].status = orderStatus.Refunded;
        }
        else if ((products[order.productId].status == productStatus.Closed || products[order.productId].status == productStatus.Processed) && order.status == orderStatus.Placed) {
            placedOrders[orderHash].status = orderStatus.Shipping;
        }
        emit orderUpdated(placedOrders[orderHash].status);
    }
    
    //Return the orderId if the customer placed an order for the product
    function getOrderId(bytes32 productId) public view customerOnly returns(bytes32) {
        bytes32 orderId = keccak256(abi.encodePacked(productId, msg.sender));
        if (placedOrders[orderId].orderId > 0) {
            return placedOrders[orderId].orderId;
        }
        
    } 
    
    //Returns the status of the order to a valid customer
    function getOrderStatus(bytes32 orderHash, bytes32 orderSecret) public view customerOnly isValidOrder(orderHash, orderSecret) returns (orderStatus) {
        return placedOrders[orderHash].status;
    }
    
    //Returns the status of the advertised product
    function getProductStatus(bytes32 productId) public view returns (productStatus) {
        return products[productId].status;
    }
    
}
