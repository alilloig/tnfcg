import NonFungibleToken from "./NonFungibleToken.cdc"
import MetadataViews from "./MetadataViews.cdc"
import FungibleToken from "./FungibleToken.cdc"
import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
import TradingFungiblePack from "./TradingFungiblePack.cdc"
import FlowToken from "./FlowToken.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import MetadataViews from 0xf8d6e0586b0a20c7
//import FungibleToken from 0xf8d6e0586b0a20c7
//import TradingFungiblePack from 0xf8d6e0586b0a20c7
//import FlowToken from 0xf8d6e0586b0a20c7

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

    // -----------------------------------------------------------------------
    // TradingNonFungibleCardGame contract interface Events
    // -----------------------------------------------------------------------

    // Emitted when a TNFCG contract is created
    pub event ContractInitialized()

    // Emitted when a new CardInfo struct is created
    pub event CardCreated(id: UInt32, metadata: {String:String})

    // Events for Set-Related actions
    //
    // Emitted when a new Set is created
    pub event SetCreated(setID: UInt32)
    // Emitted when a new Card is added to a Set
    pub event CardAddedToSet(setID: UInt32, CardID: UInt32)
    // Emitted when a Set is locked, meaning Cards cannot be added
    pub event SetPrintingStoped(setID: UInt32)
    // Emitted when a Card is minted from a Set
    pub event TNFCMinted(tnfcID: UInt64, CardID: UInt32, setID: UInt32, serialNumber: UInt32)

    // Events for Collection-related actions
    //
    // Emitted when a tnfc is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)
    // Emitted when a tnfc is deposited into a Collection
    pub event Deposit(id: UInt64, to: Address?)

    // Emitted when a Card is destroyed
    pub event TNFCDestroyed(id: UInt64)

    // Named Paths
    //
    pub let PrintedCardsStoragePath: StoragePath
    pub let PrintedCardsPublicPath: PublicPath
    pub let PrintedCardsPrivatePath: PrivatePath
    pub let AdminStoragePath: StoragePath
    pub let PackFulfilerStoragePath: StoragePath
    pub let PackFulfilerPrivatePath: PrivatePath



    // Variable size dictionary of Card structs
    access(contract) var cardDatas: {UInt32: WnWCard}

    // Variable size dictionary of Set resources
    access(contract) var sets: @{UInt32: WnWSet}


    // The ID that is used to create Cards. 
    // Every time a Card is created, CardID is assigned 
    // to the new Card's ID and then is incremented by 1.
    pub var nextCardID: UInt32

    // The ID that is used to create Sets. Every time a Set is created
    // setID is assigned to the new set's ID and then is incremented by 1.
    pub var nextSetID: UInt32
    // totalSupply
    // The total number of WnW that have been minted
    //
    pub var totalSupply: UInt64


    pub struct WnWCard: TradingNonFungibleCardGame.Card {
        pub let cardID: UInt32
        pub let metadata: {String: String}

        init(metadata: {String: String}) {
            self.cardID = WnW.nextCardID
            self.metadata = metadata
        }
    }

    pub struct WnWTNFCData: TradingNonFungibleCardGame.TNFCData {

        // The ID of the Play that the Moment references
        pub let cardID: UInt32
        
        // The ID of the Set that the Moment comes from
        pub let setID: UInt32

        // The id of the card within the set
        pub let rarity: UInt8

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        pub let collectorNumber: UInt32

        init(cardID: UInt32, setID: UInt32, rarity: UInt8, collectorNumber: UInt32){
            self.cardID = cardID
            self.setID = setID
            self.rarity = rarity
            self.collectorNumber = collectorNumber
        }
    }

    // This is an implementation of a custom metadata view for WnW TNFC.
    // This view contains the card metadata.
    //
    pub struct WnWTNFCMetadataView {

        pub let name: String?
        pub let setName: String?
        pub let rarity: String?
        pub let collectorNumber: UInt32
        pub let cardID: UInt32
        pub let setID: UInt32
        pub let numTNFCsInSet: UInt32?
        // añadir coste, color, tipo, reglas, fuerza, resistencia... aqui se definiria el game design
        // con lo que hay queda definido nada más el coleccionable, y sin arte ojo

        init(
            name: String?,
            setName: String?,
            rarity: String?,
            collectorNumber: UInt32,
            cardID: UInt32,
            setID: UInt32,
            numTNFCsInSet: UInt32?
        ) {
            self.name = name
            self.setName = setName
            self.rarity = rarity
            self.collectorNumber = collectorNumber
            self.cardID = cardID
            self.setID = setID
            self.numTNFCsInSet = numTNFCsInSet
        }
    }

    // NFT
    // A Card as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, TradingNonFungibleCardGame.TradingNonFungibleCard {
        // The token's ID
        pub let id: UInt64
        
        // The token's card
        pub let data: {TradingNonFungibleCardGame.TNFCData}
        
        // initializer
        init(initID: UInt64, cardID: UInt32, setID: UInt32, rarity: UInt8, collectorNumber: UInt32){
            pre {
                //faltan comprobaciones de si esta vacio card templates
            }
            self.id = initID
            //estos arrays estan deliberadamente mal pensados por que pueden ser accedidos desde fuera
            self.data = WnWTNFCData(cardID: cardID, setID: setID, rarity: rarity, collectorNumber: collectorNumber)
        }

        pub fun name(): String {
            return WnW.getCardMetaDataByField(cardID: self.data.cardID, field: "name") ?? ""
        }

        pub fun description(): String {
            let setName: String = WnW.getSetName(setID: self.data.setID) ?? ""
            let collectorNumber: String = self.data.collectorNumber.toString()
            return "A set "
                .concat(setName)
                .concat(" tnfc with collector number ")
                .concat(collectorNumber)
        }

         pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>(),
                Type<WnWTNFCMetadataView>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name(),
                        description: self.description(),
                        thumbnail: MetadataViews.HTTPFile("")
                    )
                case Type<WnWTNFCMetadataView>():
                    return WnWTNFCMetadataView(
                        name: WnW.getCardMetaDataByField(cardID: self.data.cardID, field: "name"),
                        setName: WnW.getSetName(setID: self.data.setID),
                        rarity: WnW.getCardMetaDataByField(cardID: self.data.cardID, field: "rarity"),
                        collectorNumber: self.data.collectorNumber,
                        cardID: self.data.cardID,
                        setID: self.data.setID,
                        numTNFCsInSet: WnW.getNumTNFCsInSet(setID: self.data.setID, cardID: self.data.cardID)
                    )
            }

            return nil
        }       

    }

    pub struct WnWSetData: TradingNonFungibleCardGame.SetData{
        pub let setID: UInt32
        pub let name: String
        pub let rarities: {UInt8: String}
        access(contract) let cardsByRarity: {UInt8: [UInt32]}
        access(contract) let printing: Bool
        access(contract) let numerMintedPerCard: {UInt32: UInt32}
        init(setID: UInt32){
            let set = &WnW.sets[setID] as &WnWSet
            self.setID = setID
            self.name = set.name
            self.rarities = set.rarities
            self.cardsByRarity = set.cardsByRarity
            self.printing = set.printing
            self.numerMintedPerCard = set.numberMintedPerCard

        }
    }


    pub resource WnWSet: TradingNonFungibleCardGame.Set{
        
        // Unique ID for the set
        pub let setID: UInt32
        // Name of the Set
        // ex. "Times when the Toronto Raptors choked in the Cardoffs"
        pub let name: String

        // Indicates if the Set is currently locked.
        // When a Set is created, it is unlocked 
        // and Plays are allowed to be added to it.
        // When a set is locked, Plays cannot be added.
        // A Set can never be changed from locked to unlocked,
        // the decision to lock a Set it is final.
        // If a Set is locked, Plays cannot be added, but
        // TNFCs can still be minted from Plays
        // that exist in the Set.
        // esto lo cambiamos para definir el conceto de printing si se pueden 
        // imprimir mas sobres del set o no
        access(contract) var printing: Bool

        // De aquí no pasa definir las rarities, entiendo que desde aqui 
        // queda definido el concepto, y hay que ver como afecta eso a cards
        // que pasa de ser un feliz array a un diccionario con clave la rareza
        // pues ya esta no? que puto mejor que tener en el set publico:
        // {1: "Common", 2: "Uncommon", 3: "Rare"}
        // los sobres referenciarian a esta rareza tambien, tendrán que tener un
        // diccionario de 
        pub let rarities: {UInt8: String}

        // Array of plays that are a part of this set.
        // When a card is added to the set, its ID gets appended here.
        // The ID does not get removed from this array when a Play is retired.
        access(contract) var cardsByRarity: {UInt8: [UInt32]}

        // Mapping of Card IDs that indicates the number of TNFCs 
        // that have been minted for specific Plays in this Set.
        // When a Moment is minted, this value is stored in the Moment to
        // show its place in the Set, eg. 13 of 60.
        access(contract) var numberMintedPerCard: {UInt32: UInt32}


        // Mapping (no estamos tan mal!!) de los IDs de las cartas minteadas
        // para hacer el sorteito y saber que id extraer de todas las impresas
        access(contract) var tnfcMintedIDsByRarity: {UInt8: [UInt64]}

        init(setID: UInt32, name: String, rarities: {UInt8: String}){
            self.setID = setID
            self.name = name
            self.printing = true
            self.rarities = rarities
            self.cardsByRarity = {}
            self.numberMintedPerCard = {}
            self.tnfcMintedIDsByRarity = {}
        }
    }
    
    /*ESTO SOBRA??? SOLO ES PARA BORROW???? */
    // This is the interface that users can cast their WnW Collection as
    // to allow others to deposit WnW into their Collection. It also allows for reading
    // the details of WnW in the Collection.
    pub resource interface WnWCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection)
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
    pub resource Collection: WnWCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection {
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
            // comprobación de tipo???
            let token <- token as! @WnW.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }
        
        // batchDeposit takes a Collection object as an argument
        // and deposits each contained NFT into this Collection
        pub fun batchDeposit(tokens: @NonFungibleToken.Collection) {

            // Get an array of the IDs to be deposited
            let keys = tokens.getIDs()

            // Iterate through the keys in the collection and deposit each one
            for key in keys {
                self.deposit(token: <-tokens.withdraw(withdrawID: key))
            }

            // Destroy the empty Collection
            destroy tokens
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

        pub fun borrowViewResolver(id: UInt64): &AnyResource{MetadataViews.Resolver} {
            let nft = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
            let WnWNFT = nft as! &WnW.NFT
            return WnWNFT as &AnyResource{MetadataViews.Resolver}
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


/*****     
******
******
******          Lo del admin de aqui pabajo
******
******
******
******/

    pub resource Administrator{

        // createNewPackFulfiler
        //
        // Function that creates and returns a new PackFulfiler resource
        //
        pub fun createNewPackFulfiler(printedCardsCollectionProviderCapability: Capability<&{NonFungibleToken.Provider, WnWCollectionPublic}>, allowedAmount: UFix64): @PackFulfiler {
            //emit PackFulfilerCreated(allowedAmount: allowedAmount)
            return <- create PackFulfiler(printedCardsCollectionProviderCapability: printedCardsCollectionProviderCapability, allowedAmount: allowedAmount)
        }

        // createNewCardCreator
        // Function that creates and returns a new CardCreator resource
        //
        pub fun createNewPackCreator(): @CardCreator{
            //emit PackCreatorCreated()
            return <- create CardCreator()
        }
    }
    
    /* 
    pub resource SetInitializer: TradingNonFungibleCardGame.SetInitializer{
        
        // A capability allowing this resource to deposit the NFTs created 
        // a lo mejó aqui habia que hacer la creación de las capabilities
        access(contract) let printedCardsCollectionPublic: Capability<&{WnWCollectionPublic}>
        
        pub fun startSet(set: {TradingNonFungibleCardGame.SetInfo}, printedCardsCollectionPublic: &{NonFungibleToken.CollectionPublic}){

        }

        init(printedCardsCollectionCapability: Capability<&{WnWCollectionPublic}>){
            self.printedCardsCollectionPublic = printedCardsCollectionCapability
        }
    }

    pub resource SetPrintRunner: TradingNonFungibleCardGame.SetPrintRunner{
        
        // A capability allowing this resource to deposit the NFTs created 
        // 
        access(contract) let printedCardsCollectionPublic: Capability<&{WnWCollectionPublic}>
        
        pub fun printRun(set: {TradingNonFungibleCardGame.SetInfo}, printedCardsCollectionPublic: &{NonFungibleToken.CollectionPublic}){

        }
        init(printedCardsCollectionCapability: Capability<&{WnWCollectionPublic}>){
            self.printedCardsCollectionPublic = printedCardsCollectionCapability
        }
    }
    */

    pub resource CardCreator: TradingNonFungibleCardGame.CardCreator{
        
        pub fun createNewCard(metadata: {String: String}): UInt32{
            var newCard = WnWCard(metadata: metadata)
            let newID = newCard.cardID

            WnW.nextCardID = WnW.nextCardID + (1 as UInt32)

            emit CardCreated(id: newID, metadata: metadata)

            WnW.cardDatas[newID] = newCard

            return newID
            
        }

        pub fun batchCreateNewCards(metadatas: [{String: String}]): [UInt32]{
            var newCardsIDs: [UInt32] = []

            for metadata in metadatas{
                var newCard = WnWCard(metadata: metadata)
                let newID = newCard.cardID
                WnW.nextCardID = WnW.nextCardID + (1 as UInt32)
                emit CardCreated(id: newID, metadata: metadata)
                WnW.cardDatas[newID] = newCard
                newCardsIDs.append(newID)
            }
            return newCardsIDs
        }

    }

    pub resource PackFulfiler: TradingNonFungibleCardGame.PackFulfiler{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let printedCardsCollectionProviderCapability: Capability<&{NonFungibleToken.Provider, WnWCollectionPublic}>

        //se puede tener una variable publica en un recurso pero no en un contrato verdad???
        pub var allowedAmount: UFix64

        // fulfilPacks
        //
        // Only method to get new WnW Cards
		// and deposit it in the recipients collection using their collection reference
        //
		pub fun fulfilPacks(setID: UInt8, amount: UFix64, packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic}){
			pre{
                //habrá que comprobar
            }

            //hay que crear una collection de cartas con las cartas aleatorias sacadas de las cartas impresas, capability a esas cartas impresas en init o set up admin account
            
            let keys: [UInt8] = [1,2]
            for key in keys {
                //packsOwnerCardCollectionPublic.deposit(token: <- create WnW.NFT(initID: WnW.totalSupply, initData: WnWCardInfo, initSet: set))
            }
            /* 
            // deposit it in the recipient's account using their reference
            */
            //aqui mas bien que esto de arriba habria que llamar a la funcion que te devolviese tantas cartas*amount del set que sea
            //return la collection provider de nfts que salen de los packs
            
        }

        init(printedCardsCollectionProviderCapability: Capability<&{NonFungibleToken.Provider, WnWCollectionPublic}>, allowedAmount: UFix64){
            self.printedCardsCollectionProviderCapability = printedCardsCollectionProviderCapability
            self.allowedAmount = allowedAmount
        }
    }
    

    // -----------------------------------------------------------------------
    // Witchcraft&Wizardry contract-level function definitions
    // -----------------------------------------------------------------------    

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



    // getSetName returns the name that the specified Set
    //            is associated with.
    // 
    // Parameters: setID: The id of the Set that is being searched
    //
    // Returns: The name of the Set
    pub fun getSetName(setID: UInt32): String? {
        // Don't force a revert if the setID is invalid
        return WnW.sets[setID]?.name
    }

    pub fun getNumberMintedPerCard(setID: UInt32): {UInt32: UInt32}? {
        let numberMintedPerCard = WnW.sets[setID]?.numberMintedPerCard
        return numberMintedPerCard
    }

    // getCardMetaDataByField returns the metadata associated with a 
    //                        specific field of the metadata
    //                        Ex: field: "Team" will return something
    //                        like "Memphis Grizzlies"
    // 
    // Parameters: cardID: The id of the Card that is being searched
    //             field: The field to search for
    //
    // Returns: The metadata field as a String Optional
    pub fun getCardMetaDataByField(cardID: UInt32, field: String): String? {
        // Don't force a revert if the cardID or field is invalid
        if let card = WnW.cardDatas[cardID] {
            return card.metadata[field]
        } else {
            return nil
        }
    }

    // getNumTNFCsInSet return the number of TNFC that have been 
    //                        minted from a certain edition.
    //
    // Parameters: setID: The id of the Set that is being searched
    //             cardID: The id of the Card that is being searched
    //
    // Returns: The total number of TNFCs 
    //          that have been minted from an edition
    pub fun getNumTNFCsInSet(setID: UInt32, cardID: UInt32): UInt32? {
        if let numberMintedPerCard = self.getNumberMintedPerCard(setID: setID){

            // Read the numMintedPerCard
            let amount = numberMintedPerCard[cardID]

            return amount
        } else {
            // If the set wasn't found return nil
            return nil
        }
    }


    // initializer
    //
	init() {
        pre{
            // checks that there is a flow token receiver on the account
            self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).check<>()
        }
        //
        // Almacenamiento Cartas impresas
        self.PrintedCardsStoragePath = /storage/WnWPrintedCardsCollection
        // Capability pa ver cartas impresas
        self.PrintedCardsPublicPath = /public/WnWPrintedCardsCollection
        //Capability pa sacar cartas
        self.PrintedCardsPrivatePath = /private/WnWPrintedCardsCollection

        // Almacenamiento recurso admin
        self.AdminStoragePath = /storage/WnWAdmin
        // Almacenamiento pack fulfiler
        self.PackFulfilerStoragePath = /storage/WnWPackFulfiler
        // Capability para fulfilear packs
        self.PackFulfilerPrivatePath = /private/WnWPackFulfiler

        self.nextCardID = 1
        self.nextSetID = 1
        // Initialize the total supply
        self.totalSupply = 0

        self.cardDatas = {}
        self.sets <- {}

        /**   SETUP ADMIN ACCOUNT EMBERDÁ, pa llevarlo a una tx hay que cambiar
         **   que en vez de que Admin implemente las interfaces las implementen
         **   recursos como estaba antes (está comentado)
         **/  

        // Create the one true Admin object and deposit it into the conttract account.
        self.account.save(<- create Administrator(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
 