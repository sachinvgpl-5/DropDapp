# DropDapp
A decentralized e-commerce application written on the Ethereum blockchain that allows sellers such as wholesalers or suppliers to directly advertise their products, specifying a minimum order limit, a maximum order limit and the offer period. On conclusion of the offer period, if the minimum number of orders have been placed, the orders are placed. Else the customers are refunded.

Instructions:
*************
Here are the steps to deploy and test the smart contract:
*********************************************************
	1) Extract the contents of the zip file.
	
	2) Download and Install Node.js (version 10.15) and the package manager npm (version 6.4) based on your operating system.
	
	3) Open command prompt and Install Truffle using
		npm install-g truffle
	
	4) Download Ganache and install it by clicking on the downloaded file. Once it is installed, open it and click on Quickstart button.
	
	5) Ganache is the local Ethereum client and by default it is configured to run on localhost. It provides 10 accounts, each with 100 mock ethers.
	
	6) In the downloaded folder, run:
		npm install
	
	7) The extracted DropDapp-contact folder contains the following:
		contracts
		migrations
		test
		truffle-config.js
	
	8) cd into the Drop-Dapp contact folder and run:
		truffle migrate --reset 
	   to deploy the smart contract on the Ganache blockchain. A build folder will be created.
	
	9) Run 	
		truffle console 
	
		The prompt changes to 
			truffle(development)>
	10) Deploy an instance of the DropDapp contact and save it in the ‘instance’ variable using 
		let instance = await DropDapp.deployed( )
	
	11) Get the list of accounts and store them in a variable ‘accounts’ using:
		let accounts= await web3.eth.getAccounts()


Use Case 1: Place 3 orders and successfully complete orders
***********************************************************
	1) Register accounts[1] as a seller and run:
		instance.registerSeller({from: accounts[1]})
				A JSON object consisting of the transaction hash and receipt is returned.
	
	2) Advertise a product with 
		productid = ‘0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44’
	 	price = ‘2’
		minOrder = ‘4’
		maxOrder=’5’ , using 
		
			instance.advertiseProduct(“0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44”,"2","2","3",{from: accounts[1]})

		A JSON consisting of the transaction hash and receipt are returned.
	
	3) Register 3 customers.
		a) First call instance.generateSecret(secret) to generate bytes32 secrets for the customers. Use the secret to call registerCustomer() to register the customers.

		b) For customer 1(using secret string “user1@secret”):

			instance.registerCustomer("0xfeda1df1e45b92a035e7779f908d04dba0ffae574d129d7c5309f9276dda3c5f", {from: accounts[2]})

		   For customer 2(using secret string “user2@secret”):

			instance.registerCustomer("0xa26dcd11977fa4149dbc9522ea46b63d1894dc27482ad6cef5fc336ca9af85ec",{from: accounts[3]})

		   For customer 3(using secret string “user3secret”):

			instance.registerCustomer("0x70e611fcde9e3002e35fa374c4fd947d52c22b541da1303c46016e8d6fac9c81",{from: accounts[4]})

	4) Using the productId and an order secret, place orders for each of the customers.

		For customer1 using productId1 and order secret “order1@secret”:

			instance.placeOrder("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44","0x8f191f7bca006ab1da80113352451c03d6f8583f7f7e69ad933dc9147df89e70", {from: accounts[2],value: 2000000000000000000})

		For customer2 using productId1 and order secret “order2@secret”:

			instance.placeOrder("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44","0x9db39cc6b6a7cf935e32ed27f1ee346e43f97679326d8ce502f276b57e44676b", {from: accounts[3],value: 2000000000000000000})

		For customer3 using productId1 and order secret “order3@secret”:

			instance.placeOrder("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44","0xe8513fcfa11f6318ed78cfe2c8970defb0a7062473bf06eee9ade6b0c502d083", {from: accounts[4],value: 2000000000000000000})



	5) For each customer, call getOrderId(productId) and use the hash32 value returned along with the ‘order secret’ used to place the order to check order status using getOrderStatus(orderHash, orderSecret)

		In order to test the withdrawOrder() function, for customer3 using the order hash and the ‘order secret’

			instance.withdrawOrder("0x904c300f8e2ad3c3896a46435467f2900386443807473f6f2facfbfacf756113","0xe8513fcfa11f6318ed78cfe2c8970defb0a7062473bf06eee9ade6b0c502d083", {from: accounts[4]})

		The account will be refunded and the order status would have changed to ‘Cancel’ represented by 1 which can be checked using:

			instance.getOrderStatus("0x904c300f8e2ad3c3896a46435467f2900386443807473f6f2facfbfacf756113","0xe8513fcfa11f6318ed78cfe2c8970defb0a7062473bf06eee9ade6b0c502d083", {from: accounts[4]})

	6) The seller ends the offer by calling endOffer(productId1).

		instance.endOffer("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44", {from: accounts[1]})

		The product status changes to Closed, represented by 1 when we call:

		instance.getProductStatus("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44")




	7) The seller can then process order by calling processOrder(productId1).

 				instance.processOrder("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44", {from: accounts[1]})
		
	   The seller’s account receives the payment for all the orders placed and product status changes to Processed represented by 2 which can be checked by calling.

				instance.getProductStatus("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44")

	8) The customers can get an update on their order status by calling orderUpdate(ordeHash, orderSecret). 

		instance.orderUpdate("0xa0a7b2e8ad1a88e6072ad1a17feae1910a69921c04b0e30caf5875b38838171f","0x8f191f7bca006ab1da80113352451c03d6f8583f7f7e69ad933dc9147df89e70", {from:accounts[2]})

	   The order status gets updated to Shipping represented by 3 which can be checked when we call
		instance.getOrderStatus("0xa0a7b2e8ad1a88e6072ad1a17feae1910a69921c04b0e30caf5875b38838171f","0x8f191f7bca006ab1da80113352451c03d6f8583f7f7e69ad933dc9147df89e70", {from:accounts[2]})



Use Case 2: Place orders lower than minimum value and get refund
****************************************************************
	1) Repeat steps 1 through 4 from use case 1, but place fewer orders than the minCount. For example, if the value of minCount in step 2 is 3, place only 2 orders as shown below:
		instance.advertiseProduct("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44","2","3","5",{from: accounts[1]})

		instance.placeOrder("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44","0x8f191f7bca006ab1da80113352451c03d6f8583f7f7e69ad933dc9147df89e70",{from:accounts[2],value: 2000000000000000000})

		instance.placeOrder("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44","0x9db39cc6b6a7cf935e32ed27f1ee346e43f97679326d8ce502f276b57e44676b",{from:accounts[3],value: 2000000000000000000})

	2) End the offer.
		instance.endOffer("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44", {from:accounts[1]})
			
	   The product status changes to Terminated represented by 3 when we call:
							instance.getProductStatus("0x6a3d624bdb0dc469b062cee7949b38b93ed102603ef8336717bbfb47cb159c44",{from:accounts[1]})


	3) The customers can process their refund using orderUpdate(orderHash, orderSecret)

		instance.orderUpdate("0x595ae3558a44cf539db47dc683677ac6905eea0f5afb7dcf71c38994ed53a405","0x8f191f7bca006ab1da80113352451c03d6f8583f7f7e69ad933dc9147df89e70",{from: accounts[2]})
			
	4) The order status changes to Refunded represented by 2 when we call:

		instance.getOrderStatus("0x595ae3558a44cf539db47dc683677ac6905eea0f5afb7dcf71c38994ed53a405","0x8f191f7bca006ab1da80113352451c03d6f8583f7f7e69ad933dc9147df89e70",{from: accounts[2]})
							



