import NonFungibleToken from "./NonFungibleToken.cdc"
import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FungibleToken from "./FungibleToken.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import MetadataViews from 0xf8d6e0586b0a20c7
//import FungibleToken from 0xf8d6e0586b0a20c7

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

    //mai events
    pub event SetInitialized(setName: String)
    pub event PacksFulfiled(amount: UFix64)

    // Named Paths
    //
    pub let PrintedCardsStoragePath: StoragePath
    pub let PrintedCardsPublicPath: PublicPath
    pub let AdminStoragePath: StoragePath
    pub let PrintedCardsPrivatePath: PrivatePath

    // totalSupply
    // The total number of WnW that have been minted
    //
    pub var totalSupply: UInt64

    pub struct SetInfo: TradingNonFungibleCardGame.SetInfo {
        pub let name: String
        pub let id: UInt64
        pub let printing: Bool  
        init(name: String, id: UInt64){
            self.name = name
            self.id = id
            self.printing = true
        }
    }

    pub struct CardInfo: TradingNonFungibleCardGame.CardInfo {
        
        pub let cardID: UInt32
        pub let set: SetInfo
        pub let name: String
        pub let rarity: UInt8
        pub let rules: {String: String}
        pub let metadata: {String: String}

        init(cardID: UInt32, set: SetInfo, name: String, rarity: UInt8, rules: {String: String}, metadata: {String: String}) {
            self.cardID = cardID
            self.set = set
            self.name = name
            self.rarity = rarity
            self.rules = rules
            self.metadata = metadata
        }
    }

    /*Que queda por definir? Una estructura de set y un diccionario de cartas*/
    // setCards
    // Diccionario con clave la id de la carta y valor {rareza, CardInfo}
    // Darle unas vueltitas para ver como hacerlo mejor a la hora de decidir cuando reimprimir
    //pub var setCards: {UInt16: {UInt8: CardInfo}}





    // NFT
    // A Card as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, TradingNonFungibleCardGame.TradingNonFungibleCard {
        // The token's ID
        pub let id: UInt64
        // The token's card
        pub let card: CardInfo
        // The card's set
        pub let set: SetInfo
        
        // initializer
        //faltan comprobaciones de si esta vacio card templates rollo ?? panic
        init(initID: UInt64, initData: CardInfo, initSet: SetInfo) {
            self.id = initID
            //estos arrays estan deliberadamente mal pensados por que pueden ser accedidos desde fuera
            self.card = initData
            self.set = initSetID
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
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.HTTPFile(url: self.imageURL)
                    )
            }

            return nil
        }       

    }
    
    /*ESTO SOBRA??? SOLO ES PARA BORROW???? */
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

    pub resource Administrator{

        // createNewPackSeller
        //
        // Function that creates and returns a new PackSeller resource
        //
        pub fun createNewSetInitializer(packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>,allowedAmount: UFix64): @PackSeller {
            emit SetInitializerCreated(allowedAmount: allowedAmount)
            return <- create PackSeller(packSellerFlowTokenCapability: packSellerFlowTokenCapability, allowedAmount: allowedAmount)
        }
        // createNewPackOpener
        //
        // Function that creates and returns a new PackMinter resource
        //
        pub fun createNewPackFulfiler(packFulfilerCapability: Capability<&{TradingNonFungibleCardGame.PackFulfiler}>, printedCardsCollection: WnWCollectionPublic): @PackOpener {
            emit PackFulfilerCreated(allowedAmount: allowedAmount)
            return <- create PackFulfiler(printedCardsCollectionProviderCapability: packFulfilerCapability, WnWCollectionPublic: printedCardsCollection)
        }


    }

    pub resource SetInitializer: TradingNonFungibleCardGame.SetInitializer{
        pub fun startSet(set: SetInfo, printedCardsCollectionPublic: &{NonFungibleToken.CollectionPublic}){

        }
    }

    pub resource PackFulfiler: TradingNonFungibleCardGame.PackFulfiler{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let printedCardsCollectionProviderCapability: Capability<&{NonFungibleToken.Provider, WnWCollectionPublic}>

        // fulfilPacks
        //
        // Only method to get new WnW Cards
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun fulfilPacks(set: SetInfo, amount: UFix64, packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic}){
			pre{
                //habrá que comprobar
            }

            //hay que crear una collection de cartas con las cartas aleatorias sacadas de las cartas impresas, capability a esas cartas impresas en init o set up admin account
            
            let keys: [UInt8] = [1,2]
            for key in keys {
                packsOwnerCardCollectionPublic.deposit(token: <- create WnW.NFT(initID: WnW.totalSupply, initData: CardInfo, initSet: set))
            }
            /* 
            // deposit it in the recipient's account using their reference
            */
            //aqui mas bien que esto de arriba habria que llamar a la funcion que te devolviese tantas cartas*amount del set que sea
            //return la collection provider de nfts que salen de los packs
            
        }

        init(printedCardsCollectionProviderCapability: Capability<&{NonFungibleToken.Provider, WnWCollectionPublic: WnWCollectionPublic}>){
            self.printedCardsCollectionProviderCapability = printedCardsCollectionProviderCapability
        }
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
        // Almacenamiento Cartas impresas
        self.PrintedCardsStoragePath = /storage/WnWPrintedCardsCollection
        // Almacenamiento recurso admin
        self.AdminStoragePath = /storage/WnWAdmin
        // Capability pa ver cartas impresas
        self.PrintedCardsPublicPath = /public/WnWPrintedCardsCollection
        //Capability pa sacar cartas
        self.PrintedCardsPrivatePath = /private/WnWPrintedCardsCollection


        // Initialize the total supply
        self.totalSupply = 0

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
 