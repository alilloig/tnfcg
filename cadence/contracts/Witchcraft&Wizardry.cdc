import NonFungibleToken from "./NonFungibleToken.cdc"
import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
import MetadataViews from "./MetadataViews.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import MetadataViews from 0xf8d6e0586b0a20c7

/**

## The very first trading non fungible card game featuring true random on-chain packs.

## `Witchcraft and Wizardry, Trading Non-Fungible Card Game` contract.

## `Card` resource

The core resource type that represents a TnFCG card in the smart contract.

## `Collection` Resource

The resource that stores a user's TnFCG card collection.
It includes a few functions to allow the owner to easily
move cards in and out of the collection.

## `CardProvider` and `CardReceiver` resource interfaces
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

*/

// The main TnFCG contract interface. Other TnFCG contracts will
// import and implement this interface
//
pub contract WnW: NonFungibleToken, TradingNonFungibleCardGame {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event CardMinted(id: UInt64)
    pub event CardBurned(id: UInt64)

    // Named Paths
    //
    pub let PrintedCardsStoragePath: StoragePath
    pub let PrintedCardsPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath
    pub let AdminStoragePath: StoragePath

    // totalSupply
    // The total number of WnW that have been minted
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
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {
        // The token's ID
        pub let id: UInt64
        // The token's card
        //pub let data: CardInfo
        // initializer
        //faltan comprobaciones de si esta vacio card templates rollo ?? panic
        init(initID: UInt64, initCardTemplateID: UInt8) {
            self.id = initID
            //self.data = WnW.cardTemplates[initCardTemplateID]
        }

        pub fun imageCID(): String {
            return "WnW.images[self.kind]![self.rarity]!"
        }

         pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: "self.name()",
                        description: "self.description()",
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.imageCID(), 
                            path: "sm.png"
                        )
                    )
            }

            return nil
        }       

    }

    // This is the interface that users can cast their WnW Collection as
    // to allow others to deposit WnW into their Collection. It also allows for reading
    // the details of WnW in the Collection.
    pub resource interface WnWCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowTNFCGCard(id: UInt64): &WnW.NFT? {
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
    pub resource Collection: WnWCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
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
            let token <- token as! @WnW.NFT

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
        pub fun borrowTNFCGCard(id: UInt64): &WnW.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &WnW.NFT
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
        init(){
            
        }
        /** 
        pub fun createNewPackOpener(allowedAmount: UFix64): @PackOpener {
            //emit??
            return <- create PackOpener(allowedAmount: allowedAmount)
        }
        */
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
	pub resource NFTMinter {

		// mintNFT
        // Mints a new NFT with a new ID
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun mintNFT(recipient: &{NonFungibleToken.CollectionPublic}, typeID: UInt8) {
            emit CardMinted(id: WnW.totalSupply)

			// deposit it in the recipient's account using their reference
			recipient.deposit(token: <-create WnW.NFT(initID: WnW.totalSupply, initTypeID: typeID))

            WnW.totalSupply = WnW.totalSupply + (1 as UInt64)
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
    // If an account does not have a WnW.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &WnW.NFT? {
        let collection = getAccount(from)
            .getCapability(WnW.PrintedCardsPublicPath)!
            .borrow<&WnW.Collection{WnW.WnWCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust WnW.Collection.borowTNFCGCard to get the correct itemID
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
        self.AdminStoragePath = /storage/WnWAdmin

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
 