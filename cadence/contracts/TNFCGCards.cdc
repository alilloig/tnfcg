import NonFungibleToken from "./NonFungibleToken.cdc"

/**

## The Flow Trading Non-Fungible Card Game standard

## `TradingNonFungibleCardGame` contract interface

The interface that all trading non-fungible card game sets contracts could conform to.
If a user wants to deploy a new TnFCG set contract, their contract would need
to implement the TradingNonFungibleTokenCardGame interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `TnFCG` resource

The core resource type that represents an TnFCG set in the smart contract.

## `Collection` Resource

The resource that stores a user's TnFCG set card collection.
It includes a few functions to allow the owner to easily
move cards in and out of the collection.

## `Vault` resource

Each account that owns set packs would need to have an instance
of the Vault resource stored in their account storage.

The Vault resource has methods that the owner and other users can call.

## `CardProvider` and `CardReceiver` resource interfaces nft

These interfaces declare functions with some pre and post conditions
that require the Collection to follow certain naming and behavior standards.

They are separate because it gives the user the ability to share a reference
to their Collection that only exposes the fields and functions in one or more
of the interfaces. It also gives users the ability to make custom resources
that implement these interfaces to do various things with the cards.

By using resources and interfaces, users of TnFCG smart contracts can send
and receive cards peer-to-peer, without having to interact with a central ledger
smart contract.

To send a card to another user, a user would simply withdraw the card
from their Collection, then call the deposit function on another user's
Collection to complete the transfer.

## `PacksProvider`, `PacksReceiver`, and `PacksBalance` resource interfaces

These interfaces declare pre-conditions and post-conditions that restrict
the execution of the functions in the Vault.

They are separate because it gives the user the ability to share
a reference to their Vault that only exposes the fields functions
in one or more of the interfaces.

It also gives users the ability to make custom resources that implement
these interfaces to do various things with the packs.
For example, a faucet can be implemented by conforming
to the Provider interface.

By using resources and interfaces, users of TnFCG contracts
can send and receive packs peer-to-peer, without having to interact
with a central ledger smart contract. To send packs to another user,
a user would simply withdraw the packs from their Vault, then call
the deposit function on another user's Vault to complete the transfer.

*/

// The main TnFCG contract interface. Other TnFCG contracts will
// import and implement this interface
//
pub contract TNFCGCards: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, typeID: UInt64)

    // Named Paths
    //
    pub let PrintedCardsStoragePath: StoragePath
    pub let PrintedCardsPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath

    // totalSupply
    // The total number of TNFCGCards that have been minted
    //
    pub var totalSupply: UInt64

    // onPrinting
    // The printing status of the set. If false, no cards can be minted
    //
    pub var onPrinting: Bool
    
    // setCards
    // Diccionario con clave la id de la carta y valor {rareza, CardInfo}
    // Darle unas vueltitas para ver como hacerlo mejor a la hora de decidir cuando reimprimir
    //MAL!!! ESTO VA A SER DEL SET!!!!
    //pub var setCards: {UInt16: {UInt8: CardInfo}}

    pub struct CardInfo {
        pub let cardID: UInt32
        pub let setID: UInt32
        pub let name: String
        pub let rarity: UInt8
        pub let rules: {String: String}
        pub let metadata: {String: String}

        init(cardID: UInt32, setID: UInt32, name: String, rarity: UInt8, rules: {String: String}, metadata: {String: String}) {
            self.cardID = cardID
            self.setID = setID
            self.name = name
            self.rarity = rarity
            self.rules = rules
            self.metadata = metadata
        }
    }



    // NFT
    // A Card as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT {
        // The token's ID
        pub let id: UInt64
        // The token's type, e.g. 3 == Hat
        pub let typeID: UInt64

        // initializer
        //
        init(initID: UInt64, initTypeID: UInt64) {
            self.id = initID
            self.typeID = initTypeID
        }
    /**
        // The token's ID
        pub let id: UInt64
        // The token's card
        pub let data: CardInfo
        // initializer
        //faltan comprobaciones de si esta vacio card templates rollo ?? panic
        init(initID: UInt64, initCardTemplateID: UInt8) {
            self.id = initID
            self.data = self.cardTemplates[initCardTemplateID]
        }
     */
    }

    // This is the interface that users can cast their TNFCGCards Collection as
    // to allow others to deposit TNFCGCards into their Collection. It also allows for reading
    // the details of TNFCGCards in the Collection.
    pub resource interface TNFCGCardsCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowTNFCGCard(id: UInt64): &TNFCGCards.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow TNFCGCard reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of TNFCGCard NFTs owned by an account
    //
    pub resource Collection: TNFCGCardsCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @TNFCGCards.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowTNFCGCard
        // Gets a reference to an NFT in the collection as a TNFCGCard,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the TNFCGCard.
        //
        pub fun borrowTNFCGCard(id: UInt64): &TNFCGCards.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &TNFCGCards.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    pub resource Administrator {

        // createNewMinter
        //
        // Function that creates and returns a new minter resource
        //
        pub fun createNewMinter(allowedAmount: UFix64): @NFTMinter {
            return <-create NFTMinter()
        }

        /** 
        pub fun createNewPackOpener(allowedAmount: UFix64): @PackOpener {
            //emit??
            return <- create PackOpener(allowedAmount: allowedAmount)
        }
        */

        




    }


    //PackOpener
    // ESTE ES EL PACK OPENER DE PACKS; AQUI HAY QUE HACER EL DE CARDS
    // que tiene que hacer? dar nfts aleatorios-ish
    //
    // ReResource object that token admin accounts can hold to receive packs and burn them
    // Los UFix hay que cambiarlos a enteros, no se valen decimales
    /** 
    pub resource PackOpener {

        pub var allowedAmount: UFix64
        // openPacks
        //
        // Function that mints new tokens, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun openPacks(payment: @TNFCGPacks.Vault): @TNFCGCards.Vault {
            pre {
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount"
            }
            
            self.allowedAmount = self.allowedAmount - amount
            emit TokensBurned(amount: amount)
            //como se queman los FT? pos en vez de ese return eso
            //y como se usa esto pa que se minteen X? pues creo q simplemente Cards tiene una funcion que llama N veces a minter
            return <-create Vault(balance: amount)
        }
        init(allowedAmount: UFix64) {
            self.allowedAmount = allowedAmount
        }

    }
    */

    //PackPrinter
    // Un recurso para que un admin mintee N cartas


    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	pub resource NFTMinter {

		// mintNFT
        // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64) {
            emit Minted(id: TNFCGCards.totalSupply, typeID: typeID)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create TNFCGCards.NFT(initID: TNFCGCards.totalSupply, initTypeID: typeID))

            TNFCGCards.totalSupply = TNFCGCards.totalSupply + (1 as UInt64)
		}
    /** 
	    // mintNFT
        // Mints a new NFT with a new ID
	    // and deposit it in the recipients collection using their collection reference
        //
	    access(self) fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt64, rarity: UInt8) {
            emit Minted(id: alphaWTR.totalSupply, typeID: typeID)
	        
            // deposit it in the recipient's account using their reference
	        recipient.deposit(token: <-create alphaWTR.NFT(initID: alphaWTR.totalSupply, initTypeID: typeID))
            alphaWTR.totalSupply = alphaWTR.totalSupply + (1 as UInt64)
	    }

        access(contract) fun mintSET(recipient: &{NonFungibleToken.CollectionPublic}){
            for key in dictionary.keys {
            let value = dictionary[key]!
        }
    */
	}

    // fetch
    // Get a reference to a TNFCGCard from an account's Collection, if available.
    // If an account does not have a TNFCGCards.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &TNFCGCards.NFT? {
        let collection = getAccount(from)
            .getCapability(TNFCGCards.PrintedCardsPublicPath)!
            .borrow<&TNFCGCards.Collection{TNFCGCards.TNFCGCardsCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust TNFCGCards.Collection.borowTNFCGCard to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowTNFCGCard(id: itemID)
    }

    // initializer
    //
	init() {
        // Set our named paths
        self.PrintedCardsStoragePath = /storage/PrintedCardsCollection
        self.PrintedCardsPublicPath = /public/PrintedCardsCollection
        self.MinterStoragePath = /storage/CardsMinter
        self.AdminStoragePath = /storage/TNFCGCardsAdmin

        // Initialize the total supply
        self.totalSupply = 0
        // Initialize the on printing flag of the set
        self.onPrinting = true
        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)
        // create a new empty collection for storing the printed cards
        let printedCards <- create Collection()
        // save it to the account
        self.account.save(<-printedCards, to: self.PrintedCardsStoragePath)

        // Create the one true Admin object and deposit it into the conttract account.
        let admin <- create Administrator()
        self.account.save(<-admin, to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
 