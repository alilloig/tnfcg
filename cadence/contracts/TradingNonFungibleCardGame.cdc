//import NonFungibleToken from "./NonFungibleToken.cdc"
//import FungibleToken from "./FungibleToken.cdc"
//import TradingFungiblePack from "./TradingFungiblePack.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7

/**

## The Flow Trading Non-Fungible Card standard

## `TradingNonFungibleCardGame` contract interface

The interface that all trading non fungible card NFT based games contracts could 
conform to. If a user wants to deploy a new tnfcg contract, their contract would need
to implement the TradingNonFungibleCardGame interface.

Their contract would have to follow all the rules and naming that the interface specifies.

## `TradingNonFungibleCard` interface resource
The interface that NFT resource should conform to be a TNFC

## `TNFCGCollection` interface resource
Interface for allowing the TNFC collection to get queried but not to get NFTs
deposited in order to ensure the printed TNFCs pool integrity

## `Set` interface resource
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

/// TradingNonFungibleCardGame
/// The main TNFCG contract interface. TNFCG contracts will
/// import and implement this interface
///
pub contract interface TradingNonFungibleCardGame {
    
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

    // -----------------------------------------------------------------------
    // TNFCG interface contract-level fields.
    // These contain actual values that are stored in the smart contract.
    // -----------------------------------------------------------------------

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

    // -----------------------------------------------------------------------
    // Trading Non Fungible Card Game interface contract-level Composite Type definitions
    // -----------------------------------------------------------------------

    // These are just *definitions* for Types that any TNFCG will use. 
    // These definitions do not contain actual stored values, but an instance 
    // (or object) of one of these Types can be created by this contract that 
    // contains stored values.

    // Card is a Struct that holds metadata associated 
    // with a specific TNFCG Card, such as name, cost, types, rules, etc.
    //
    // TNFC NFTs will all reference a single Card as the owner of
    // its metadata. The Cards are publicly accessible, so anyone can
    // read the metadata associated with a specific Card ID
    //
    pub struct interface Card {
        // The unique ID for the Card
        pub let cardID: UInt32
        // Stores all the metadata about the Card as a string mapping
        // This is not the long term way NFT metadata will be stored. It's a 
        // temporary construct while we figure out a better way to do metadata.
        // Or is just fine with MetadataViews??
        pub let metadata: {String: String}
    }

    // Structure holding the info that makes a NFT a TNFC
    pub struct interface TNFCData {
        // The ID of the Card that the TNFC references
        pub let cardID: UInt32
        // The ID of the Set that the TNFC comes from
        pub let setID: UInt32
        // The id of the rarity assigned to the card within the set
        pub let rarityID: UInt8
        // The place in the edition that this TNFC was minted
        // Otherwise know as the serial number
        pub let serialNumber: UInt32
    }

    // NFTs should conform also to this interface in order to store its TNFCData
    pub resource interface TradingNonFungibleCard{
        pub let data: {TNFCData}
    }

    // This interfaces allows to expose a Collection's NFTs data
    // without allowing anyone to deposit any NFTs
    pub resource interface TNFCGCollection {
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT?{
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow TNFCGCard reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // A Set is a grouping of Cards that exists in the TNFCG, each of them
    // appearing at a certain rarity. The admin can add Cards to a Set so that 
    // the set can mint TNFCs that reference that carddata.
    // The TNFCs that are minted by a Set will be stored in the TNFCG collection
    // and its IDs stored in mintedTNFCsIDsByRarity for distributing them when
    // packs are opened
    //
    pub resource interface Set{
        
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

        // addPackInfo adds a type of pack to the set
        //
        // Parameters: setID: The ID of the Set that the pack that is being added belongs to
        //             packRarities: The rarities of the TNFCs in the packs
        //             packRaritiesDistribution: The number of TNFCs of each rarity per pack
        //
        // Pre-Conditions:
        // The set printing must NOT be in progress
        //
        pub fun addPackInfo(packInfo: {TradingFungiblePack.PackInfo}){
            pre{
                !self.printingInProgress: "No more packs can be added when the set is beeing printed"
            }
        }

        // addCardsByRarity adds a card to the set
        //
        // Parameters: [cardID]: The IDs of the Cards that are being added
        //              rarity: The id of the cards' set rarity appearance
        //
        // Pre-Conditions:
        // The Set printing must be in progress
        //
        pub fun addCardsByRarity(cardIDs: [UInt32], rarity: UInt8) {
            pre {
                !self.printingInProgress: "Cannot add the card to the Set after the set has started to be printed."
            }
        }
        
        // startPrinting() unlocks the set so TNFCs can be minted
        //
        // Pre-Conditions:
        // The Set should be currently not beeing printed
        // There should be at least one pack added to the set
        // The set should contain at least one card
        // Post-Conditions:
        // The Set printing should have been started
        // The set rarities distribution must be initialized for each rarity in set
        //
        pub fun startPrinting(){
            pre {
                !self.printingInProgress: "The set is already beeing printed"
                self.packsInfo.keys.length != 0: "There should be at least one kind of pack before printing the set"
                self.cardsByRarity.keys.length != 0: "There should be at least one card in the set"
            }
            post {
                self.printingInProgress: "The printing must be in progress"
                self.raritiesDistribution.keys.length == self.rarities.keys.length: "The set's rarity distribution must be setted"
            }
        }

        // printRun mint TNFCs, stores them in the contract account's collection
        // and stores its IDs by rarity
        //
        // Parameters: packID: The id of the packs that the TNFCs will be fulfiling
        //             quantity: The desired amount of printings to be done
        //
        // Pre-Conditions:
        // Set printing must be in progress
        //
        pub fun printRun(packID: UInt8, quantity: UInt64): @NonFungibleToken.Collection{
            pre{
                self.printingInProgress: "The printing must be in progress"
            }
        }

        // fulfilPacks() select the TNFCs IDs among the printedTNFCsIDs for fulfiling
        // a certain amount of packs
        //
        // Pre-Conditions:
        // Set printing must be in progress
        //
        pub fun fulfilPacks(packID: UInt8, amount: UFix64): [UInt64]{
            pre{
                self.printingInProgress: "The printing must be in progress"
            }
        }

        // stopPrinting() locks the Set so that no more TNFCs can be printed
        //
        // Pre-Conditions:
        // The Set should be currently beeing printed
        // Post-Conditions:
        // The Set printing should have been stopped
        pub fun stopPrinting(){
            pre {
                self.printingInProgress
            }
            post {
                !self.printingInProgress
            }
        }
    }

    // An auxiliary data struct for accessing the sets' dictionary data in a 
    // secure and nil-proof way
    pub struct interface QuerySetData{
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
        pub fun getSetRarities(): {UInt8: String}?
        pub fun getRaritiesDistribution(): {UInt8: UFix64}?
        pub fun getCardsByRarity(): {UInt8: [UInt32]}?
        pub fun getNumberMintedPerCard(): {UInt32: UInt32}?
        pub fun getPacksInfo(): {UInt8: {TradingFungiblePack.PackInfo}}?
        pub fun getMintedTNFCsIDsByRarity(): {UInt8: [UInt64]}?
    }

    // -----------------------------------------------------------------------
    // TradingNonFungibleCardGame contract admin resources
    // -----------------------------------------------------------------------
    
    /// Card creator
    ///
    /// The interface that enforces the requirements for creating cards into the TNFCG
    ///
    pub resource interface CardCreator{
        pub fun createNewCard(metadata: {String: String}): UInt32
        pub fun batchCreateNewCards(metadatas: [{String: String}]): [UInt32]
    }


    /// Set Manager
    ///
    /// The interface that enforces the requirements for creating a new set,
    /// adding cards and packs to it, and handle its printing status
    ///
    pub resource interface SetManager{
        // createSet() specifying set's name and rarities
        // Returns: setID
        pub fun createSet(name: String, rarities: {UInt8: String}): UInt32
        // addPackInfo() see set.addPackInfo()
        pub fun addPackInfo(setID: UInt32, packInfo: {TradingFungiblePack.PackInfo})
        // addCardsByRarity() see set.addCardsByRarity()
        pub fun addCardsByRarity(setID: UInt32, cardIDs: [UInt32], rarity: UInt8)
        // startPrinting() see set.startPrinting()
        pub fun startPrinting(setID: UInt32)
        // stopPrinting() see set.stopPrinting()
        pub fun stopPrinting(setID: UInt32)
    }

    /// Set PrintRunner
    ///
    /// The interface that defines the function for creating new copies of the 
    /// cards (tnfcs) in a set 
    ///
    pub resource interface SetPrintRunner{
        // printRun() creates the needed amount of NFTs to satisfy the desired
        // quantity of printings, when called by TradingFungiblePack.printRun() 
        // through a private capability. The amount of NFTs per printing is calculated
        // in base to the set's and pack's raritiesDistribution.
        pub fun printRun(setID: UInt32, packID: UInt8, quantity: UInt64)
    }

    /// Pack fulfiler
    ///
    /// The interface that defines the functions for getting the TNFCs in return
    /// for the packs
    ///
    pub resource interface SetPackFulfiler{
        // fulfilPacks() selects the cards that should be given to the owner in 
        // order to fulfil a certain amount of packs and stores its IDs next to 
        // the TNFCs address, when called by TradingFungiblePack.openPacks() 
        // through a private capability
        pub fun fulfilPacks(setID: UInt32, packID: UInt8, amount: UFix64, owner: Address)
        // retrieveTNFCs() transfers the owned cards to the owner's Collection
        // this should be called by the Admin through a private capability any
        // time after any user has opened any amount of packs
        pub fun retrieveTNFCs(owner: Address)
    }
}
 