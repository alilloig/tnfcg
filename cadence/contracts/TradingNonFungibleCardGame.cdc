//import NonFungibleToken from "./NonFungibleToken.cdc"
//import FungibleToken from "./FungibleToken.cdc"
//import TradingFungiblePack from "./TradingFungiblePack.cdc"
import NonFungibleToken from 0xf8d6e0586b0a20c7
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7

/**

## The Flow Trading Non-Fungible Card standard

## `NonFungibleToken` contract interface

The interface that all non-fungible token contracts could conform to.
If a user wants to deploy a new nft contract, their contract would need
to implement the NonFungibleToken interface.

Their contract would have to follow all the rules and naming
that the interface specifies.

## `NFT` resource

The core resource type that represents an NFT in the smart contract.

## `Collection` Resource

The resource that stores a user's NFT collection.
It includes a few functions to allow the owner to easily
move tokens in and out of the collection.

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

*/

// The main NFT contract interface. Other NFT contracts will
// import and implement this interface
//
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
    // TNFCG contract-level fields.
    // These contain actual values that are stored in the smart contract.
    // -----------------------------------------------------------------------

    // The ID that is used to create Cards. 
    // Every time a Card is created, CardID is assigned 
    // to the new Card's ID and then is incremented by 1.
    pub var nextCardID: UInt32

    // The ID that is used to create Sets. Every time a Set is created
    // setID is assigned to the new set's ID and then is incremented by 1.
    pub var nextSetID: UInt32

    // The total number of Top shot Moment NFTs that have been created
    // Because NFTs can be destroyed, it doesn't necessarily mean that this
    // reflects the total number of NFTs in existence, just the number that
    // have been minted to date. Also used as global moment IDs for minting.
    pub var totalSupply: UInt64



    // -----------------------------------------------------------------------
    // Trading Non Fungible Card Game interface contract-level Composite Type definitions
    // -----------------------------------------------------------------------
    // These are just *definitions* for Types that this contract
    // and other accounts can use. These definitions do not contain
    // actual stored values, but an instance (or object) of one of these Types
    // can be created by this contract that contains stored values.
    // -----------------------------------------------------------------------

    // Card is a Struct that holds metadata associated 
    // with a specific NBA Card, like the legendary moment when 
    // Ray Allen hit the 3 to tie the Heat and Spurs in the 2013 finals game 6
    // or when Lance Stephenson blew in the ear of Lebron James.
    //
    // Moment NFTs will all reference a single Card as the owner of
    // its metadata. The Cards are publicly accessible, so anyone can
    // read the metadata associated with a specific Card ID
    //

    pub struct interface Card {

        // The unique ID for the Card
        pub let cardID: UInt32

        // Stores all the metadata about the Card as a string mapping
        // This is not the long term way NFT metadata will be stored. It's a temporary
        // construct while we figure out a better way to do metadata.
        pub let metadata: {String: String}
    }

    pub struct interface TNFCData {

        // The ID of the Play that the Moment references
        pub let cardID: UInt32

        // The ID of the Set that the Moment comes from
        pub let setID: UInt32

        // The id of the card within the set
        pub let rarityID: UInt8

        // The place in the edition that this Moment was minted
        // Otherwise know as the serial number
        pub let serialNumber: UInt32

    }

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

    // A Set is a grouping of Cards that have occured in the real world
    // that make up a related group of collectibles, like sets of baseball
    // or Magic cards. A Card can exist in multiple different sets.
    // Aqui va tiradita de pisto, cards de magic que se imprimen en un set
    //

    // The admin can add Cards to a Set so that the set can mint TNFCs
    // that reference that playdata.
    // The TNFCs that are minted by a Set will be listed as belonging to
    // the Set that minted it, as well as the Play it references.
    //
    //
    // If the admin locks the Set, no more Plays can be added to it, but 
    // TNFCs can still be minted.
    //
    // If retireAll() and lock() are called back-to-back, 
    // the Set is closed off forever and nothing more can be done with it.
    pub resource interface Set{
        
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
        pub var printingInProgress: Bool

        // Toda esta chapa es vieja de antes de definir la Rarity en pack
        // De aquí no pasa definir las rarities, entiendo que desde aqui 
        // queda definido el concepto, y hay que ver como afecta eso a cards
        // que pasa de ser un feliz array a un diccionario con clave la rareza
        // pues ya esta no? que puto mejor que tener en el set publico:
        // {1: "Common", 2: "Uncommon", 3: "Rare"}
        // los sobres referenciarian a esta rareza tambien, tendrán que tener un
        // diccionario de 
        access(contract) let rarities: {UInt8: String}

        access(contract) var raritiesDistribution: {UInt8: UFix64}

        //  INFORMACION DE LOS PACKS QUE SE VENDEN DE UN SET
        //
        pub var nextPackID: UInt8
        access(contract) var packsInfo: {UInt8: {TradingFungiblePack.PackInfo}}

        // Array of card that are a part of this set.
        // When a card is added to the set, its ID gets appended here.
        access(contract) var cardsByRarity: {UInt8: [UInt32]}

        // Mapping of Card IDs that indicates the number of TNFCs 
        // that have been minted for specific Cards in this Set.
        // When a TNFC is minted, this value is stored in the TNFC to
        // show its place in the Set, eg. 13 of 60.
        access(contract) var numberMintedPerCard: {UInt32: UInt32}


        // Mapping (no estamos tan mal!!) de los IDs de las cartas minteadas
        // para hacer el sorteito y saber que id extraer de todas las impresas
        access(contract) var mintedTNFCsIDsByRarity: {UInt8: [UInt64]}

        
        //
        // Set public functions
        //

        // addPackInfo adds a type of pack to the set
        //
        // Parameters: setID: The ID of the Set that the pack that is being added belongs to
        //             packRarities: The rarities of the TNFCs in the packs
        //             packRaritiesDistribution: The number of TNFCs of each rarity per pack
        //
        // Pre-Conditions:
        // ¿?¿?¿?¿? vaya repaso de comentarios guapo que hay que hacer
        // The Card needs to be an existing card
        // The Set needs to be not locked
        // The Card can't have already been added to the Set
        //
        pub fun addPackInfo(packInfo: {TradingFungiblePack.PackInfo}){
            pre{
                !self.printingInProgress: "No more packs can be added when the set is beeing printed"
                //check que el set existe como poco
            }
        }

        // addCardsByRarity adds a card to the set
        //
        // Parameters: [cardID]: The IDs of the Cards that are being added
        //              rarity: The id of the cards' set rarity appearance
        //
        // Pre-Conditions:
        // The Card needs to be an existing card
        // The Set needs to be not locked
        // The Card can't have already been added to the Set
        //
        pub fun addCardsByRarity(cardIDs: [UInt32], rarity: UInt8) {
            pre {
                !self.printingInProgress: "Cannot add the card to the Set after the set has started to be printed."
            }
        }
        
        // startPrinting() locks the Set so that no more cards can be printed
        //
        // Pre-Conditions:
        // The Set should be currently not beeing printed
        // Post-Conditions:
        // The Set printing should have been started
        pub fun startPrinting(){
            pre {
                !self.printingInProgress: "The set is already beeing printed"
                //self.packsInfo.keys.length > 1: "There should be at least one kind of pack before printing the set"
                self.cardsByRarity.keys.length > 1: "There should be at least one card in the set"
            }
            post {
                self.printingInProgress: "The printing must be in progress"
                self.raritiesDistribution.keys.length == self.rarities.keys.length: "The set's rarity distribution must be setted"
            }
        }

        pub fun printRun(packID: UInt8, quantity: UInt64): @NonFungibleToken.Collection{
            pre{
                self.printingInProgress: "The printing must be in progress"
            }
        }

        // fulfilPacks() THA RANDOM BITCH!!!!!!!!!!!!!!
        //
        // Pre-Conditions:
        //
        // Post-Conditions:
        //
        pub fun fulfilPacks(packID: UInt8, amount: UFix64): [UInt64]{
            pre{
                self.printingInProgress: "The printing must be in progress"
            }
        }

        // stopPrinting() locks the Set so that no more cards can be printed
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
    }

    // -----------------------------------------------------------------------
    // TradingNonFungibleCardGame contract admin resources
    // -----------------------------------------------------------------------
    /// Pack fulfiler
    ///
    /// The interface that enforces the requirements for opening Packs
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
        pub fun createSet(name: String, rarities: {UInt8: String}): UInt32
        pub fun addPackInfo(setID: UInt32, packInfo: {TradingFungiblePack.PackInfo})
        pub fun addCardsByRarity(setID: UInt32, cardIDs: [UInt32], rarity: UInt8)
        pub fun startPrinting(setID: UInt32)
        pub fun stopPrinting(setID: UInt32)
    }

    /// Set PrintRunner
    ///
    /// The interface that enforces the requirements for creating new copies of the cards in a set
    ///
    pub resource interface SetPrintRunner{
        /// this should create a number of NFTs depending on the number of packs createds
        pub fun printRun(setID: UInt32, packID: UInt8, quantity: UInt64)
    }

    /// Pack fulfiler
    ///
    /// The interface that enforces the requirements for opening Packs
    ///
    pub resource interface SetPackFulfiler{
        /// openPacks takes a Vault and destroys it returning the number of opened packs
        pub fun fulfilPacks(setID: UInt32, packID: UInt8, amount: UFix64, packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic})
    }
}
 