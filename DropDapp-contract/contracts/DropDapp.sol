pragma solidity >=0.4.22 <=0.8.0;

contract DropDapp {
    
    //address used to deploy contract
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
    
    enum productStatus{Open, Closed, Terminated} 
    
    enum orderStatus{Placed, Cancelled, Refunded, Shipping}
    
    
    //Product struct
    struct Product {
        string productId;
        uint256 price;
        uint minCount;
        uint maxCount;
        uint orderCount;
        address payable sellerId; 
        productStatus status;
    }
    
    
    //Order Struct
    struct Order {
        string productId;
        bytes32 orderId;
        address customerId;
        orderStatus status;
    }
    
    //mapping to keep track of sellers
    mapping(address => Seller) sellers;
    
    //mapping to keep track of customers
    mapping(address => Customer) customers;
    
    //mapping to keep track of product details using productId
    mapping(string => Product) products;
    
    //mapping to keep track of placed orders using orderHash
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
    
    modifier isUniqueProduct(string memory productId) {
        require(products[productId].sellerId == address(0));
        _;
    }
    
    modifier isOfferValid(string memory productId) {
        require(products[productId].status == productStatus.Open);
        _;
    }
    
    modifier isValidOrder(bytes32 orderHash) {
        require (orderHash == keccak256(abi.encodePacked(placedOrders[orderHash].productId, msg.sender, customers[placedOrders[orderHash].customerId].secret)));
        _;
    }


    constructor() public {
        admin = msg.sender;
    }
    

    function generateSecret(string memory secret) public pure returns (bytes32 generatedSecret) {
        generatedSecret = keccak256(abi.encodePacked(secret));
        return generatedSecret;
    }
    
    function registerSeller() public {
        Seller memory seller;
        seller.sellerId = msg.sender;
        seller.isRegistered = true;
        sellers[seller.sellerId] = seller; 
    }
    
    function registerCustomer(bytes32 secret) public {
        Customer memory customer;
        customer.customerId = msg.sender;
        customer.isRegistered = true;
        customer.secret = secret;
        customers[customer.customerId] = customer;
        
    } 
    
    function advertiseProduct(string memory productId, uint price, uint minCount, uint maxCount) public sellerOnly isUniqueProduct(productId) {
        Product memory product;
        product.productId = productId;
        product.price = price*(1 ether);
        product.minCount = minCount;
        product.maxCount = maxCount;
        product.sellerId = msg.sender;
        product.orderCount = 0;
        product.status = productStatus.Open;
        products[productId] = product;
        
    }
    
    function endOffer(string memory productId) public sellerOnly {
        require(products[productId].sellerId == msg.sender);
        require(products[productId].status == productStatus.Open);
        
        if(products[productId].orderCount >= products[productId].minCount) {
            products[productId].status = productStatus.Closed;
        }
        else
        {
            products[productId].status = productStatus.Terminated;
        }
    }
    
    
    function placeOrder(string memory productId) public payable customerOnly isOfferValid(productId) returns(bytes32) {


        
        require(products[productId].orderCount + 1 <= products[productId].maxCount);
        require((products[productId].price) <= msg.value);
        // products[productId].sellerId.transfer(msg.value);

        Order memory order;
        order.productId = productId;
        order.orderId = keccak256(abi.encodePacked(productId, msg.sender, customers[msg.sender].secret));
        order.customerId = msg.sender;
        order.status = orderStatus.Placed;
        placedOrders[order.orderId] = order;
        products[productId].orderCount += 1;
    }
    
    
    function withdrawOrder(bytes32 orderHash) isOfferValid(placedOrders[orderHash].productId) isValidOrder(orderHash) public {
        
        // require(placedOrders[orderHash].customerId == msg.sender);
        require(placedOrders[orderHash].status == orderStatus.Placed);
        refundCustomer(placedOrders[orderHash].productId, orderHash, msg.sender);
        products[placedOrders[orderHash].productId].orderCount -= 1;
        placedOrders[orderHash].status = orderStatus.Cancelled;
    }
    
    function refundCustomer(string memory productId, bytes32 orderHash, address payable customer) internal {
        if (orderHash == keccak256(abi.encodePacked(productId, customer, customers[placedOrders[orderHash].customerId].secret))) 
            customer.transfer(products[productId].price);
    }
    
    function processOrder(string memory productId) payable public sellerOnly {
        if(products[productId].status == productStatus.Closed) {
            Product memory product = products[productId];
            uint amount = product.price * product.orderCount;
            product.sellerId.transfer(amount);
        }
    }
    
    function orderUpdate(bytes32 orderHash) public customerOnly isValidOrder(orderHash) returns (orderStatus) {
        Order memory order = placedOrders[orderHash];
        if (products[order.productId].status == productStatus.Terminated && order.status == orderStatus.Placed) {
            refundCustomer(order.productId, orderHash, msg.sender);
            placedOrders[orderHash].status = orderStatus.Refunded;
        }
        else if (products[order.productId].status == productStatus.Closed && order.status == orderStatus.Placed) {
            placedOrders[orderHash].status = orderStatus.Shipping;
        }
        return placedOrders[orderHash].status;
    }
    
    
    function getOrderId(string memory productId) public view customerOnly returns(bytes32) {
        bytes32 orderId = keccak256(abi.encodePacked(productId, msg.sender, customers[msg.sender].secret));
        if (placedOrders[orderId].orderId > 0) {
            return placedOrders[orderId].orderId;
        }
        
    } 
    
    function getOrderStatus(bytes32 orderHash) public view customerOnly isValidOrder(orderHash) returns (orderStatus) {
        return placedOrders[orderHash].status;
    }
    
    function getProductStatus(string memory productId) public view returns (productStatus) {
        return products[productId].status;
    }
    
}


