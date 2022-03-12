//import NonFungibleToken from "./NonFungibleToken.cdc"
//import MetadataViews from "./MetadataViews.cdc"
//import FungibleToken from "./FungibleToken.cdc"
//import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
//import TradingFungiblePack from "./TradingFungiblePack.cdc"
//import FlowToken from "./FlowToken.cdc"
//import TF from "./TradingFunctions.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import MetadataViews from 0xf8d6e0586b0a20c7
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import FlowToken from 0xf8d6e0586b0a20c7
import TF from 0xf8d6e0586b0a20c7

/**

## The very first trading non fungible card game featuring true random on-chain packs.

## `Witchcraft and Wizardry, Trading Non-Fungible Card Game` contract.

## `Card` resource

The core resource type that represents a TnFCG card in the smart contract.

## `Collection` Resource

The resource that stores a user's TnFCG card collection.
It includes a few functions to allow the owner to easily
move TNFCs in and out of the collection.

## `CardProvider` and `CardReceiver` resource interfaces
These interfaces declare functions with some pre and post conditions
that require the Collection to follow certain naming and behavior standards.

They are separate because it gives the user the ability to share a reference
to their Collection that only exposes the fields and functions in one or more
of the interfaces. It also gives users the ability to make custom resources
that implement these interfaces to do various things with the TNFCs.

By using resources and interfaces, users of TnFCG smart contracts can send
and receive TNFCs peer-to-peer, without having to interact with a central ledger
smart contract.

To send a card to another user, a user would simply withdraw the card
from their Collection, then call the deposit function on another user's
Collection to complete the transfer.

## `Provider` and `Receiver` resource interfaces

These interfaces declare functions with some pre and post conditions
that require the Collection to follow certain naming and behavior standards.

They are separate because it gives the user the ability to share a reference
to their Collection that only exposes the fields and functions in one or more
of the interfaces. It also gives users the ability to make custom resources
that implement these interfaces to do various things with the tokens.

By using resources and interfaces, users of NFT smart contracts can send
and receive tokens peer-to-peer, without having to interact with a central ledger
smart contract.

To send an NFT to another user, a user would simply withdraw the NFT
from their Collection, then call the deposit function on another user's
Collection to complete the transfer.

## `TradingNonFungibleCard` interface resource
The interface that NFT resource should conform to be a TNFC

## `TNFCGCollection` interface resource
Interface for allowing the TNFC collection to get queried but not to get NFTs
deposited in order to ensure the printed TNFCs pool integrity

## `WnWSet` resource
The resource that will be ordering the cards and asociate them to one or more
Trading Fungible Packs

## `CardCreator` interface resource
The admin only access resource that creates cards into the TNFCG

## `SetManager` interface resource
The admin only access resource that manages sets state

## `SetPrintRunner` interface resource
The admin only access resource that mints TNFCs

## `SetPackFulfiler` interface resource
The admin only access resource in charge of grant users TNFCs in return for
their packs

*/

// The main TnFCG contract interface. Other TnFCG contracts will
// import and implement this interface
//
pub contract WnW: NonFungibleToken, TradingNonFungibleCardGame {

    // Emitted when a TNFCG contract is created
    pub event ContractInitialized()

    // Emitted when a new CardInfo struct is created
    pub event CardCreated(id: UInt32, metadata: {String:String})

    // Events for Set-Related actions
    //
    // Emitted when a new Set is created
    pub event SetCreated(setID: UInt32)
    // Emitted when a new Card is added to a Set
    pub event CardAddedToSet(setID: UInt32, cardID: UInt32, rarity: UInt8)
    // Emitted when a Set is locked, meaning Cards cannot be added
    pub event SetPrintingStoped(setID: UInt32)
    // Emitted when a Card is minted from a Set
    pub event TNFCMinted(tnfcID: UInt64, cardID: UInt32, setID: UInt32, serialNumber: UInt32)

    // Events for Collection-related actions
    //
    // Emitted when a tnfc is withdrawn from a Collection
    pub event Withdraw(id: UInt64, from: Address?)
    // Emitted when a tnfc is deposited into a Collection
    pub event Deposit(id: UInt64, to: Address?)

    // Emitted when a Card is destroyed
    pub event TNFCDestroyed(id: UInt64)

    // The ID that is used to create Cards. 
    // Every time a Card is created, CardID is assigned 
    // to the new Card's ID and then is incremented by 1.
    pub var nextCardID: UInt32

    // The ID that is used to create Sets. Every time a Set is created
    // setID is assigned to the new set's ID and then is incremented by 1.
    pub var nextSetID: UInt32

    // The total number of Trading Non-Fungible Card NFTs that have been created
    // Because NFTs can be destroyed, it doesn't necessarily mean that this
    // reflects the total number of NFTs in existence, just the number that
    // have been minted to date. Also used as global moment IDs for minting.
    pub var totalSupply: UInt64

    // Variable size dictionary of Card structs
    access(contract) var cardDatas: {UInt32: WnWCard}

    // Variable size dictionary of Set resources
    access(contract) var sets: @{UInt32: WnWSet}

    // Variable holding the IDs of the opened NFTs by each account to retrieve
    // them after beeing generated secure randomly
    access(contract) var openedTNFCsIDsByAccount: {Address: [[UInt64]]}

    // Named Paths
    //
    //
    pub let OwnedTNFCsStoragePath: StoragePath
    pub let OwnedTNFCsCollectionPublicPath: PublicPath
    pub let PrintedTNFCsPrivateReceiverPath: PrivatePath
    pub let PrintedTNFCsPrivateProviderPath: PrivatePath
    pub let PrintedTNFCsPublicTNFCGCollectionPath: PublicPath
    //
    pub let AdminStoragePath: StoragePath
    //
    pub let CardCreatorStoragePath: StoragePath
    pub let CardCreatorPrivatePath: PrivatePath
    //
    pub let SetManagerStoragePath: StoragePath
    pub let SetManagerPrivatePath: PrivatePath
    //
    pub let SetPrintRunnerStoragePath: StoragePath
    pub let SetPrintRunnerPrivatePath: PrivatePath
    //
    pub let SetPackFulfilerStoragePath: StoragePath
    pub let SetPackFulfilerPrivatePath: PrivatePath

    // Card is a Struct that holds metadata associated 
    // with a specific TNFCG Card, such as name, cost, types, rules, etc.
    //
    // TNFC NFTs will all reference a single Card as the owner of
    // its metadata. The Cards are publicly accessible, so anyone can
    // read the metadata associated with a specific Card ID
    //
    pub struct WnWCard: TradingNonFungibleCardGame.Card {
        pub let cardID: UInt32
        pub let metadata: {String: String}

        init(metadata: {String: String}) {
            self.cardID = WnW.nextCardID
            self.metadata = metadata
        }
    }

    // Structure holding the info that makes a NFT a TNFC
    pub struct WnWTNFCData: TradingNonFungibleCardGame.TNFCData {

        // The ID of the Play that the Moment references
        pub let cardID: UInt32
        
        // The ID of the Set that the Moment comes from
        pub let setID: UInt32

        // The id of the card within the set
        pub let rarityID: UInt8

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        pub let serialNumber: UInt32

        init(cardID: UInt32, setID: UInt32, rarityID: UInt8, serialNumber: UInt32){
            self.cardID = cardID
            self.setID = setID
            self.rarityID = rarityID
            self.serialNumber = serialNumber
        }
    }

    // This is an implementation of a custom metadata view for WnW TNFC.
    // This view contains the card metadata.
    //
    pub struct WnWTNFCMetadataView {

        pub let name: String?
        pub let setName: String?
        pub let rarity: String?
        pub let serialNumber: UInt32
        pub let cardID: UInt32
        pub let setID: UInt32
        pub let numTNFCsInSet: UInt32?

        init(
            name: String?,
            setName: String?,
            rarity: String?,
            serialNumber: UInt32,
            cardID: UInt32,
            setID: UInt32,
            numTNFCsInSet: UInt32?
        ) {
            self.name = name
            self.setName = setName
            self.rarity = rarity
            self.serialNumber = serialNumber
            self.cardID = cardID
            self.setID = setID
            self.numTNFCsInSet = numTNFCsInSet
        }
    }

    // NFT & TNFC
    // A Trading Non-Fungible Card
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver, TradingNonFungibleCardGame.TradingNonFungibleCard {
        // The token's ID
        pub let id: UInt64
        
        // The token's card
        pub let data: {TradingNonFungibleCardGame.TNFCData}
        
        // initializer
        init(cardID: UInt32, setID: UInt32, rarityID: UInt8, serialNumber: UInt32){
            pre {
                //faltan comprobaciones de si esta vacio card templates
            }
            WnW.totalSupply = WnW.totalSupply + 1
            self.id = WnW.totalSupply
            //estos arrays estan deliberadamente mal pensados por que pueden ser accedidos desde fuera
            self.data = WnWTNFCData(cardID: cardID, setID: setID, rarityID: rarityID, serialNumber: serialNumber)
        }

        pub fun name(): String {
            return WnW.getCardMetaDataByField(cardID: self.data.cardID, field: "name") ?? ""
        }

        pub fun description(): String {
            let setName: String = WnW.getSetName(self.data.setID) ?? ""
            let serialNumber: String = self.data.serialNumber.toString()
            return "A set "
                .concat(setName)
                .concat(" tnfc copy of card ")
                .concat(self.data.cardID.toString())
                .concat(" at rarity ")
                .concat(self.data.rarityID.toString())
                .concat(" with serial number ")
                .concat(serialNumber)
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
                        setName: WnW.getSetName(self.data.setID),
                        rarity: WnW.getCardMetaDataByField(cardID: self.data.cardID, field: "rarity"),
                        serialNumber: self.data.serialNumber,
                        cardID: self.data.cardID,
                        setID: self.data.setID,
                        numTNFCsInSet: WnW.getNumTNFCsInSet(setID: self.data.setID, cardID: self.data.cardID)
                    )
            }

            return nil
        }       

    }

    // A Set is a grouping of Cards that exists in WnW, each of them
    // appearing at a certain rarity. The admin can add Cards to a Set so that 
    // the set can mint TNFCs that reference that carddata.
    // The TNFCs that are minted by a Set will be stored in the WnW collection
    // and its IDs stored in mintedTNFCsIDsByRarity for distributing them when
    // packs are opened
    //
    pub resource WnWSet: TradingNonFungibleCardGame.Set{
        
        // Unique ID for the set
        pub let setID: UInt32
        // Name of the Set
        pub let name: String

        // Indicates if the Set is currently beeing printed. Once a set is beeing
        // printed no more cards and no more packs could be added to it. Until a 
        // set's printing isn's in progress (printingInProgress = true) a set can't
        // run printings. When no more packs of the set are going to be distributed
        // the set should be stopPrinting()
        // TO-DO: different flags for not allowing to add more cards&packs and start
        // printing and to finally stop the set's printing???
        pub var printingInProgress: Bool

        // Dictionary containing rarityID and description for rarities in set
        access(contract) let rarities: {UInt8: String}

        // Dictionary of arrays of cardIDs that are a part of this set for each
        // rarityID.
        // When a card is added to the set, its ID gets appended here.
        access(contract) var cardsByRarity: {UInt8: [UInt32]}

        // Dictionary containing the amount of cards asigned to set per rarityID
        access(contract) var raritiesDistribution: {UInt8: UFix64}

        //  The ID of the next pack to be added to the set
        pub var nextPackID: UInt8
        // Dictionary containing packIDs and PackInfo for the set
        access(contract) var packsInfo: {UInt8: {TradingFungiblePack.PackInfo}}

        // Dictionary containing the IDs of the TNFCs minted for each rarityID
        access(contract) var mintedTNFCsIDsByRarity: {UInt8: [UInt64]}
        // Dictionary containing the amount of TNFCs per specific cardID that 
        // have been minted in this Set.
        access(contract) var numberMintedPerCard: {UInt32: UInt32}

        init(name: String, rarities: {UInt8: String}){
            self.setID = WnW.nextSetID
            self.name = name
            self.printingInProgress = false
            self.rarities = rarities
            self.raritiesDistribution = {}
            self.nextPackID = 1
            self.packsInfo = {}
            self.cardsByRarity = {}
            self.mintedTNFCsIDsByRarity = {}
            for rarity in rarities.keys{
                self.cardsByRarity[rarity] = []
                self.mintedTNFCsIDsByRarity[rarity] = []
            }
            self.numberMintedPerCard = {}
        }

        // addPackInfo adds a type of pack to the set
        //
        // Parameters: setID: The ID of the Set that the pack that is being added belongs to
        //             packRarities: The rarities of the TNFCs in the packs
        //             packRaritiesDistribution: The number of TNFCs of each rarity per pack
        //
        pub fun addPackInfo(packInfo: {TradingFungiblePack.PackInfo}){
            self.packsInfo[self.nextPackID] = packInfo
            // Increment the packID so that it isnt't used again
            self.nextPackID = self.nextPackID + 1
        }

        // addCardsByRarity adds a card to the set
        //
        // Parameters: [cardID]: The IDs of the Cards that are being added
        //              rarity: The id of the cards' set rarity appearance
        //
        pub fun addCardsByRarity(cardIDs: [UInt32], rarity: UInt8) {
            for card in cardIDs {
                self.addCard(cardID: card, rarity: rarity)
            }
            self.raritiesDistribution[rarity] = UFix64(self.cardsByRarity[rarity]!.length)
        }

        // startPrinting() unlocks the set so TNFCs can be minted
        //
        pub fun startPrinting(){
            self.printingInProgress = true
        }

        // printRun mint TNFCs, stores them in the contract account's collection
        // and stores its IDs by rarity
        //
        // Parameters: packID: The id of the packs that the TNFCs will be fulfiling
        //             quantity: The desired amount of printings to be done
        //
        pub fun printRun(packID: UInt8, quantity: UInt64): @NonFungibleToken.Collection{
            let packInfo = self.packsInfo[packID] ?? panic("Pack does not exist in set")
            let printedTNFCs <- WnW.createEmptyCollection()
            var completedPrintRuns: UInt64 = 0
            var sheetQuantity: UInt64 = 0
            var printedSheets: UInt64 = 0
            var rarityCardsIDs: [UInt32] = []
            log("Number of printings running: ".concat(quantity.toString()))
            while (completedPrintRuns < quantity){
                sheetQuantity = 0
                // Por cada rareza que aparece en el pack
                for rarityID in packInfo.printingRaritiesSheetsQuantities.keys {
                    sheetQuantity = packInfo.printingRaritiesSheetsQuantities[rarityID] ?? panic("Rarity does not have a sheet quantity per printing")
                    log("Printing rarity ".concat(rarityID.toString()))
                    log("Total of sheets for rarity: ".concat(sheetQuantity.toString()))
                    printedSheets = 0
                    // Tantas veces como sheets de esa rareza por printing como diga la info del pack
                    while (printedSheets < sheetQuantity){
                        // Se imprime una sheet de esa rarity (se crea un TNFC por cada Card de esa rarity en el set)
                        rarityCardsIDs = self.cardsByRarity[rarityID] ?? panic("No cards for rarity ".concat(rarityID.toString()))
                        for cardID in rarityCardsIDs{
                            let TNFC <- self.mintTNFC(cardID: cardID, setID: self.setID, rarityID: rarityID)
                            self.mintedTNFCsIDsByRarity[rarityID]!.append(TNFC.id)
                            printedTNFCs.deposit(token: <- TNFC)
                        }
                        printedSheets = printedSheets + 1
                    }
                }
                completedPrintRuns = completedPrintRuns + 1
            }

            return <- printedTNFCs
        }

        // fulfilPacks() select the TNFCs IDs among the printedTNFCsIDs for fulfiling
        // a certain amount of packs
        //
        pub fun fulfilPacks(packID: UInt8, amount: UFix64): [UInt64]{
            // array with the IDs of the NFTs that will be fulfiling the packs
            var openedTNFCsIDs: [UInt64] = []
            // auxiliar variable for holding the opened tnfc id
            var openedTNFCID: UInt64 = 0
            //index of the card randomly selected for fulfiling
            var randomTNFCIndex: UInt64 = 0
            // rarity distribution of the pack
            var rarityDistribution: UFix64 = 0.0
            // amount of TNFCs at a certain rarity that are going to be selected
            var rarityAmountToFulfil: UInt64 = 0
            // amount of TNFC (tnfc ids actually) that have already been transfered
            var rartityTransferedAmount: UInt64 = 0
            //pack info from the set
            var packInfo = self.packsInfo[packID] ?? panic("Pack does not exists in set")
            //for each rarity from the tnfcs that come into the pack get
            for rarity in packInfo.packRaritiesDistribution.keys{
                //get the quantity of tnfcs at that rarity in each pack
                rarityDistribution = packInfo.packRaritiesDistribution[rarity] ?? panic("PackInfo does not have rarity distribution")
                // get the total amount of tnfcs needed at that rarity based on the amount of packs beeing opened
                rarityAmountToFulfil = UInt64(rarityDistribution) * UInt64(amount)
                // set the counter of rarity's transfered tnfc to 0
                rartityTransferedAmount = 0
                // until we transfer as much TNFC as needed
                while (rartityTransferedAmount < rarityAmountToFulfil){
                    //get the TNFC IDs minted for that rarity
                    let rarityMintedTNFCsIDs = self.mintedTNFCsIDsByRarity[rarity] ?? panic("No tnfcs minted with this rarity")
                    //select randomly one of them
                    randomTNFCIndex = TF.generateAcotatedRandom(UInt64(rarityMintedTNFCsIDs.length))
                    //and save its id
                    openedTNFCID = rarityMintedTNFCsIDs[randomTNFCIndex]
                    //remove the id from the list of printed TNFCs
                    self.mintedTNFCsIDsByRarity[rarity]!.remove(at: randomTNFCIndex)
                    // and add it to the array that will be fulfiling the packs
                    openedTNFCsIDs.append(openedTNFCID)
                    //finally increase the amount of tnfc transfered for this amount
                    rartityTransferedAmount = rartityTransferedAmount + 1
                }
            }
            return openedTNFCsIDs
        }

        // stopPrinting() locks the Set so that no more TNFCs can be printed
        //
        pub fun stopPrinting(){
            self.printingInProgress = false
        }

        // addCard adds a card to the set
        //
        // Parameters: cardID: The ID of the Card that is being added
        //              rarity: The id of the card's set rarity appearance
        //
        access(self) fun addCard(cardID: UInt32, rarity: UInt8) {
            pre {
                WnW.cardDatas[cardID] != nil: "Cannot add the Card to Set: Card doesn't exist."
                !self.printingInProgress: "Cannot add the card to the Set after the set has been locked."
                self.numberMintedPerCard[cardID] == nil: "The card has already beed added to the set."
            }

            // Add the Card to the arrays dictionary of Cards/Rarity
            self.cardsByRarity[rarity]!.append(cardID)

            // Initialize the TNFC count to zero
            self.numberMintedPerCard[cardID] = 0

            emit CardAddedToSet(setID: self.setID, cardID: cardID, rarity: rarity)
        }
        
        access(self) fun mintTNFC(cardID: UInt32, setID: UInt32, rarityID: UInt8): @WnW.NFT{
            let numInCard = self.numberMintedPerCard[cardID]!
            let TNFC <- create WnW.NFT(cardID: cardID, setID: self.setID, rarityID: rarityID, serialNumber: numInCard)
            self.numberMintedPerCard[cardID] = numInCard + 1
            return <- TNFC
        }        
    }

    // An auxiliary data struct for accessing the sets' dictionary data in a 
    // secure and nil-proof way
    pub struct WnWQuerySetData: TradingNonFungibleCardGame.QuerySetData{
        pub let setID: UInt32
        pub let name: String
        pub let printingInProgress: Bool
        access(contract) let rarities: {UInt8: String}
        access(contract) let raritiesDistribution: {UInt8: UFix64}
        pub let nextPackID: UInt8
        access(contract) let packsInfo: {UInt8: {TradingFungiblePack.PackInfo}}
        access(contract) let cardsByRarity: {UInt8: [UInt32]}
        access(contract) let numberMintedPerCard: {UInt32: UInt32}
        access(contract) var mintedTNFCsIDsByRarity: {UInt8: [UInt64]}
        
        init(setID: UInt32){
            let set = &WnW.sets[setID] as &WnWSet
            self.setID = setID
            self.name = set.name
            self.printingInProgress = set.printingInProgress
            self.rarities = set.rarities
            self.raritiesDistribution = set.raritiesDistribution
            self.nextPackID = set.nextPackID
            self.packsInfo = set.packsInfo
            self.cardsByRarity = set.cardsByRarity
            self.numberMintedPerCard = set.numberMintedPerCard
            self.mintedTNFCsIDsByRarity = set.mintedTNFCsIDsByRarity
        }

        pub fun getSetRarities(): {UInt8: String}?{
            if (self.rarities.keys.length > 0){
                return self.rarities
            } else {
                return nil
            }
        }
        pub fun getRaritiesDistribution(): {UInt8: UFix64}?{
            if (self.raritiesDistribution.keys.length > 0){
                return self.raritiesDistribution
            } else {
                return nil
            }
        }
        pub fun getCardsByRarity(): {UInt8: [UInt32]}?{
            if (self.cardsByRarity.keys.length > 0){
                return self.cardsByRarity
            } else {
                return nil
            }
        }
        pub fun getNumberMintedPerCard(): {UInt32: UInt32}?{
            if (self.numberMintedPerCard.keys.length > 0){
                return self.numberMintedPerCard
            } else {
                return nil
            }
        }
        pub fun getPacksInfo(): {UInt8: {TradingFungiblePack.PackInfo}}?{
            if (self.packsInfo.keys.length > 0){
                return self.packsInfo
            } else {
                return nil
            }            
        }
        pub fun getMintedTNFCsIDsByRarity(): {UInt8: [UInt64]}?{
            if (self.mintedTNFCsIDsByRarity.keys.length > 0){
                return self.mintedTNFCsIDsByRarity
            } else {
                return nil
            }             
        }
    }

    // Public capability shaped interface for borrowing TNFCs
    pub resource interface WnWCollectionPublic {
        // borrowTNFC
        // Gets a reference to an NFT in the collection as a TNFC,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the TNFC.
        // (not in use, create WnWCollectionPublic??)
        pub fun borrowTNFC(id: UInt64): &WnW.NFT?
    }

    // Collection
    // A collection of TNFCGCard NFTs owned by an account
    //
    pub resource Collection: NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection, TradingNonFungibleCardGame.TNFCGCollection, WnWCollectionPublic {
    
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
        
        // borrowTNFC
        // Gets a reference to an NFT in the collection as a TNFC,
        // exposing all of its fields (including the typeID).
        // This is safe as there are no functions that can be called on the TNFC.
        // (not in use, create WnWCollectionPublic??)
        pub fun borrowTNFC(id: UInt64): &WnW.NFT? {
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

        // createNewCardCreator
        // Function that creates and returns a new CardCreator resource
        //
        pub fun createNewCardCreator(): @CardCreator{
            //emit PackPrinterCreated()
            return <- create CardCreator()
        }

        // createNewSetManager
        // Function that creates and returns a new SetManager resource
        //
        pub fun createNewSetManager(): @SetManager{
            return <- create SetManager()
        }

        // createNewPrintRunner
        // Function that creates and returns a new PrintRunner resource
        //
        pub fun createNewSetPrintRunner(printedTNFCsCollectionPrivateReceiver: Capability<&{NonFungibleToken.Receiver}>): @SetPrintRunner{
            return <- create SetPrintRunner(printedTNFCsCollectionPrivateReceiver: printedTNFCsCollectionPrivateReceiver)
        }

        // createNewSetPackFulfiler
        // Function that creates and returns a new PackFulfiler resource
        //
        pub fun createNewSetPackFulfiler(printedTNFCsCollectionPrivateProvider: Capability<&{NonFungibleToken.Provider}>): @SetPackFulfiler {
            return <- create SetPackFulfiler(printedTNFCsCollectionPrivateProvider: printedTNFCsCollectionPrivateProvider)
        }


    }

    /// Card creator
    ///
    /// The admin only access resource that creates new cards into WnW
    ///
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

    /// Set Manager
    ///
    /// The admin only access resource that manages the sets state
    ///
    pub resource SetManager: TradingNonFungibleCardGame.SetManager{

        pub fun createSet(name: String, rarities: {UInt8: String}): UInt32{
            // Create the new Set
            var newSet <- create WnWSet(name: name, rarities: rarities)

            // Increment the setID so that it isn't used again
            WnW.nextSetID = WnW.nextSetID + UInt32(1)

            let newID = newSet.setID

            emit SetCreated(setID: newSet.setID)

            // Store it in the sets mapping field
            WnW.sets[newID] <-! newSet

            return newID
        }

        pub fun addPackInfo(setID: UInt32, packInfo: {TradingFungiblePack.PackInfo}){
            
            let set = &WnW.sets[setID] as &WnWSet

            set.addPackInfo(packInfo: packInfo)
        }

        pub fun addCardsByRarity(setID: UInt32, cardIDs: [UInt32], rarity: UInt8){
            
            let set = &WnW.sets[setID] as &WnWSet

            set.addCardsByRarity(cardIDs: cardIDs, rarity: rarity)
        }

        pub fun startPrinting(setID: UInt32){
            
            let set = &WnW.sets[setID] as &WnWSet

            set.startPrinting()
        }

        pub fun stopPrinting(setID: UInt32){
            
            let set = &WnW.sets[setID] as &WnWSet

            set.stopPrinting()
        }

    }

    /// Set PrintRunner
    ///
    /// The admin only access resource that mints tnfcs
    ///
    pub resource SetPrintRunner: TradingNonFungibleCardGame.SetPrintRunner{
        // A capability allowing this resource to deposit the NFTs created 
        // 
        access(contract) let printedTNFCsCollectionPrivateReceiver: Capability<&{NonFungibleToken.Receiver}>
        
        pub fun printRun(setID: UInt32, packID: UInt8, quantity: UInt64){
            let set = &WnW.sets[setID] as &WnWSet
            let printedTNFCs <- set.printRun(packID: packID, quantity: quantity)
            let printedTNFCsIDs = printedTNFCs.getIDs()
            let printedTNFCsReceiverRef = self.printedTNFCsCollectionPrivateReceiver.borrow() ?? panic("Cannot borrow reference to printed TNFCs collection private receiver")
            for tnfcID in printedTNFCsIDs{
                printedTNFCsReceiverRef.deposit(token: <-printedTNFCs.withdraw(withdrawID: tnfcID))
            }
            destroy printedTNFCs
        }

        init(printedTNFCsCollectionPrivateReceiver: Capability<&{NonFungibleToken.Receiver}>){
            self.printedTNFCsCollectionPrivateReceiver = printedTNFCsCollectionPrivateReceiver
        }
    }


    /// Pack fulfiler
    ///
    /// The admin only access resource that selects the TNFCs for fulfiling the 
    /// packs and send them to the packs owner collection
    ///
    pub resource SetPackFulfiler: TradingNonFungibleCardGame.SetPackFulfiler{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let printedTNFCsCollectionPrivateProvider: Capability<&{NonFungibleToken.Provider}>

        // fulfilPacks()
        //
        // Calls set fulfilPacks to get the TNFCs IDs that would be distributed to
        // the owner of the fulfiledPacks
        //
		pub fun fulfilPacks(setID: UInt32, packID: UInt8, amount: UFix64, owner: Address){
            //borrow a reference to the set
            let set = &WnW.sets[setID] as &WnWSet
            //call to set fulfilPacks
            let openedTNFCsIDs = set.fulfilPacks(packID: packID, amount: amount)
            //If the account didn't open any packs previusly initialize the dictionary at key "owner"
            if (WnW.openedTNFCsIDsByAccount[owner] == nil){
                WnW.openedTNFCsIDsByAccount[owner] = []
            }
            // Add the pack's TNFCs IDs to the structure holding the opened packs info
            WnW.openedTNFCsIDsByAccount[owner]!.append(openedTNFCsIDs)
        }

        // retrieveTNFCs()
        // Only method to get new WnW Cards
		// and deposit it in the recipients collection using their collection reference
        //
        pub fun retrieveTNFCs(owner: Address){
            // Borrow a reference to the printed TNFCs collection provider of WnW
            let printedTNFCsProviderRef = self.printedTNFCsCollectionPrivateProvider.borrow() ?? panic("Cannot borrow printed TNFCs provider")
            // Borrow a reference to the TNFCs owner public collection
            let packsOwnerCardCollectionPublicRef = getAccount(owner)
                .getCapability(WnW.OwnedTNFCsCollectionPublicPath)
                .borrow<&{NonFungibleToken.CollectionPublic}>()
                ?? panic("Unable to borrow collection reference")
            // Get the array of opened packs TNFCs IDs for the owner
            let ownerOpenedPacksTNFCsIDs = WnW.openedTNFCsIDsByAccount[owner] ?? panic("No opened TNFCs for this address")
            // Empty the opened tnfcs ids for the owner in the contract field
            WnW.openedTNFCsIDsByAccount[owner] = []
            // for each pack that the user has opened
            for openedTNFCsIDs in ownerOpenedPacksTNFCsIDs{
                // for each TNFC ID of the pack
                for tnfcID in openedTNFCsIDs{
                    // withdraw the TNFC from the WnW collection and deposit in the owners collection
                    packsOwnerCardCollectionPublicRef.deposit(
                        token: <-printedTNFCsProviderRef.withdraw(withdrawID: tnfcID))
                }
            }
        }

        init(printedTNFCsCollectionPrivateProvider: Capability<&{NonFungibleToken.Provider}>){
            self.printedTNFCsCollectionPrivateProvider = printedTNFCsCollectionPrivateProvider
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
    pub fun fetch(_ from: Address, itemID: UInt64): &NonFungibleToken.NFT? {
        let collection = getAccount(from)
            .getCapability(WnW.OwnedTNFCsCollectionPublicPath)!
            .borrow<&WnW.Collection{TradingNonFungibleCardGame.TNFCGCollection}>()
            ?? panic("Couldn't get collection")
        // We trust WnW.Collection.borowTNFCGCard to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowNFT(id: itemID)
    }


    pub fun getCardsIDs(): [UInt32]?{
        if WnW.cardDatas.keys.length == 0 {
            return nil
        } else {
            return WnW.cardDatas.keys
        }        
    }


    // Al final SetData y getSetData son una forma publica facil de sacar info
    // de campos del contrato que queremos que sean de acceso restringido pero 
    // que se pueda saber su info (por que coño no impiden que se puedan escribir
    // los putos campos arrays y diccionarios????)
    pub fun getSetData(setID: UInt32): WnWQuerySetData?{
        if WnW.sets[setID] == nil {
            return nil
        } else {
            return WnWQuerySetData(setID: setID)
        }
    }

    // getSetName returns the name that the specified Set
    //            is associated with.
    // 
    // Parameters: setID: The id of the Set that is being searched
    //
    // Returns: The name of the Set
    pub fun getSetName(_ setID: UInt32): String? {
        // Don't force a revert if the setID is invalid
        return WnW.sets[setID]?.name
    }
    pub fun getSetNextPackID(_ setID: UInt32): UInt8? {
        return WnW.sets[setID]?.nextPackID
    }

    pub fun getSetPrintingInProgress(_ setID: UInt32): Bool? {
        return WnW.sets[setID]?.printingInProgress
    }
    
    pub fun getSetRarities(_ setID: UInt32): {UInt8: String}? {
        return WnW.sets[setID]?.rarities
    }

    pub fun getSetRaritiesDistribution(_ setID: UInt32): {UInt8: UFix64}? {  
        return WnW.sets[setID]?.raritiesDistribution
    }

    pub fun getSetRarityDistribution(setID: UInt32, rarityID: UInt8): UFix64? {
        let raritiesDistribution = WnW.sets[setID]?.raritiesDistribution as! {UInt8: UFix64}
        return  raritiesDistribution[rarityID]
    }

    pub fun getSetCardsByRarity(_ setID: UInt32): {UInt8: [UInt32]}? {
        return WnW.sets[setID]?.cardsByRarity
    }

    pub fun getSetNumberMintedPerCard(_ setID: UInt32): {UInt32: UInt32}? {
        return WnW.sets[setID]?.numberMintedPerCard
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
        if let numberMintedPerCard = self.getSetNumberMintedPerCard(setID){

            // Read the numMintedPerCard
            let amount = numberMintedPerCard[cardID]

            return amount
        } else {
            // If the set wasn't found return nil
            return nil
        }
    }

	init() {
        // Set storage path for TNFCs and the path to its public capability
        self.OwnedTNFCsStoragePath = /storage/WnWOwnedTNFCsCollection
        self.OwnedTNFCsCollectionPublicPath = /public/WnWOwnedTNFCsCollectionPublic
        self.PrintedTNFCsPublicTNFCGCollectionPath = /public/WnWPrintedTNFCsTNFCGCollection
        // Set the path for the private capabilities for the printedTNFCs collection
        self.PrintedTNFCsPrivateReceiverPath = /private/WnWPrintedTNFCsCollectionReceiver
        self.PrintedTNFCsPrivateProviderPath = /private/WnWPrintedTNFCsCollectionProvider
        
        // Set the storage and the private capability paths for the Admin resource
        // and its administration resources
        self.AdminStoragePath = /storage/WnWAdmin
        self.CardCreatorStoragePath = /storage/WnWCardCreator
        self.CardCreatorPrivatePath = /private/WnWCardCreator
        self.SetManagerStoragePath = /storage/WnWSetManager
        self.SetManagerPrivatePath = /private/WnWSetManager
        self.SetPrintRunnerStoragePath = /storage/WnWSetPrintRunner
        self.SetPrintRunnerPrivatePath = /private/WnWSetPrintRunner
        self.SetPackFulfilerStoragePath = /storage/WnWSetPackFulfiler
        self.SetPackFulfilerPrivatePath = /private/WnWSetPackFulfiler

        // Initialize the contract state
        self.nextCardID = 1
        self.nextSetID = 1
        self.totalSupply = 0
        self.cardDatas = {}
        self.sets <- {}
        self.openedTNFCsIDsByAccount = {}

        // Create the one true Admin object and deposit it into the conttract account.
        self.account.save(<- create Administrator(), to: self.AdminStoragePath)

        emit ContractInitialized()
	}
}
 