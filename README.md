# Witchcraft And Wizardry
## A Trading Non-Fungible Card Game

This repository contains the smart contracts and transactions that implement the core functionality of Witchcraft And Wizardry, a learning cadence project emulating a Trading Card Game with NFTs, featuring random on-chain packs, implemented as FTs, as the only way to distribute said NFTs.

### What is a Trading Non-Fungible Card Game and a Trading Fungible Pack?

The main difference of WnW with any other NFT implementation is the definition of packs as Fungible Tokens. Collectible packs for NFTs, as other NFT containing them has no sense on the blockchain, due to his open-state which would cause it's content to be known before opening the pack. But if we think in how card packs from Trading Card Games work in real life, we see we can approach them as Fungible Tokens rather than Non-Fungible ones. Until a pack is opened, it has the same value of any other pack of the same kind, the potencial value of the cards that it contains, that are unknown but are known to belong to a printed pool of cards. 

This behaviour is what this project tries to emulate. When Trading Fungible Packs (fungible tokens) are allowed to be minted, the necessary amount of Trading Non-Fungible Cards (nfts containing the info of a certain card from the set the packs belongs to) are minted and stored in the TNFCG account. Then packs can be selled to users, who can decide to open them and get some NFTs from the game collection (in the case of Witchcraft and Wizardry those NFTs are determined randonmly using the `unsafeRandom()` cadence built-in function) or to hold and trade them, since they allways could be traded latter for TNFCs with the contract.

In order to allow other TNFCGs to be created and simplifying the creation of new kind of packs, the contract interfaces `TradingNonFungibleCardGame.cdc` and `TradingFungiblePack.cdc` define the behaviour and data structs that need to be conformed respectively. Witchcraft&Wizardry and W&W Alpha Edition Packs are working examples of how to implement it.

When [Interface Implementation Requirements](https://docs.onflow.org/cadence/language/interfaces/#interface-implementation-requirements) are fully working on cadence TradingNonFungibleCardGame.cdc should `:NonFungibleToken` and TradingFungiblePack.cdc should `:FungibleToken`. 

## Contract Interfaces

### TradingNonFungibleCardGame.cdc
- A TNFCG can have any number of cards. Trading Non-Fungible Cards are NFTs copies of those cards.
- A TNFCG is made up of any number of sets. A set include any number of cards each of them at a certain rarity.
- Each set must have at least one type of pack. The pack contains a certain amount of TNFC of any of the set's rartities.
- NFT resource will also conform to TradingNonFungibleCard, that has a TNFCData field containing the relating info.
- TNFCG defines the following structs  and resource interfaces in order to handle this logic. Detailed comments and pre/post conditions can be found in the source code:

```cadence
      pub struct interface Card {
        pub let cardID: UInt32
        pub let metadata: {String: String}
      }
      pub struct interface TNFCData {
        pub let cardID: UInt32
        pub let setID: UInt32
        pub let rarityID: UInt8
        pub let serialNumber: UInt32
      }
      pub resource interface TradingNonFungibleCard{
        pub let data: {TNFCData}
      }
      pub resource interface Set{
        pub let setID: UInt32
        pub let name: String
        pub var printingInProgress: Bool
        access(contract) let rarities: {UInt8: String}
        access(contract) var raritiesDistribution: {UInt8: UFix64}
        pub var nextPackID: UInt8
        access(contract) var packsInfo: {UInt8: {TradingFungiblePack.PackInfo}}
        access(contract) var cardsByRarity: {UInt8: [UInt32]}
        access(contract) var numberMintedPerCard: {UInt32: UInt32}
        access(contract) var mintedTNFCsIDsByRarity: {UInt8: [UInt64]}
        pub fun addPackInfo(packInfo: {TradingFungiblePack.PackInfo})
        pub fun addCardsByRarity(cardIDs: [UInt32], rarity: UInt8)
        pub fun startPrinting()
        pub fun printRun(packID: UInt8, quantity: UInt64): @NonFungibleToken.Collection
        pub fun fulfilPacks(packID: UInt8, amount: UFix64): [UInt64]
        pub fun stopPrinting()
    }
```

- It also defines four admin resources for exposing capabilities to create cards, handle set info, print cards and fulfil packs:

```cadence
      pub resource interface CardCreator{
        pub fun createNewCard(metadata: {String: String}): UInt32
        pub fun batchCreateNewCards(metadatas: [{String: String}]): [UInt32]
      }
      pub resource interface SetManager{
        pub fun createSet(name: String, rarities: {UInt8: String}): UInt32
        pub fun addPackInfo(setID: UInt32, packInfo: {TradingFungiblePack.PackInfo})
        pub fun addCardsByRarity(setID: UInt32, cardIDs: [UInt32], rarity: UInt8)
        pub fun startPrinting(setID: UInt32)
        pub fun stopPrinting(setID: UInt32)
      }
      pub resource interface SetPrintRunner{
        pub fun printRun(setID: UInt32, packID: UInt8, quantity: UInt64)
      }
      pub resource interface SetPackFulfiler{
        pub fun fulfilPacks(setID: UInt32, packID: UInt8, amount: UFix64, owner: Address)
        pub fun retrieveTNFCs(owner: Address)
      }
```

### TradingFungiblePack.cdc

- A Trading Fungible Pack must belong to a set from a certain TNFCG, define a rarity distribution and a price per pack. This is all done when deploying the contract comforming to TradingFungiblePack.cdc
- TFP defines the following structure to keep the pack info:
``` cadence
    pub struct interface PackInfo {
        pub let packID: UInt8
        pub let packRaritiesDistribution: {UInt8: UFix64}
        pub let printingPacksAmount: UInt64
        pub let printingRaritiesSheetsQuantities: {UInt8: UInt64}
        pub let price: UFix64
    }
``` 
- The amount of packs per printing, and the quantity of sheets of each rarity for printing (a sheet is a copy of each card of a certain set rarity) should be calculated on the PackInfo init function when the contract is deployed. 
- In order to ensure the same distribution of TNFCs per card in each rarity, some rules have to be followed. WnWAlphaPacks enforces this checking that the printingSize (the number of packs that have to be printed to distribute at least one copy each of the rarest cards of the set) is an integer number, and that the number of sheets of each rarity that have to printed per printing are also integers. This can be easily achive having the same amount of cards in the set for each rarity and having the total number of rarest cards beeing divisible by the rarity distribution of the pack (e.g. WnW Alpha Packs features 1 rare, 2 uncommons and 3 commons per pack, and the set has 5 rares, 5 uncommon and 5 common cards).
- The pack's administrator resource can create 3 resources to manage the lyfe-cicle of the packs and the tnfcs distributed with them:
```cadence
    pub resource interface PackPrinter{
      pub var allowedAmount: UInt64
      pub fun printRun(quantity: UInt64): UInt64
    }
    pub resource interface PackSeller{
      pub fun sellPacks(
            payment: @FungibleToken.Vault,
            packsPayerPackReceiver: &{FungibleToken.Receiver},
            amount: UFix64)
    }
    pub resource interface PackOpener{
      pub fun openPacks(packsToOpen: @FungibleToken.Vault, owner: Address)
    }
```

## How to Deploy and Test Witchcraft and Wizardry using VSCode and Flow CLI
Before you start remember to have installed the VSCode extension and the Flow CLI in your enviroment. You also will be needing node.js for encoding to HEX some contracts. For the following stepswe asume that that WnW contracts will be deployed to the emulator's ServiceAccount 0xf8d6e0586b0a20c7
1. Start the flow emulator in VSCode.
2. Deploy the FungibleToken.cdc contract interface using the VSCode extension.
3. Deploy the FlowToken.cdc contract. Keep in mind that we are using a slightly modified version of this contract to add named value fields for storage and capabilities paths. As FlowToken.cdc init function takes and AuthAccount resource as a parameter you will need to run a transaction like this `flow transactions send ./cadence/transactions/flow/deploy_flow_token.cdc CONTRACT_HEX_CODE`. To get the contract's hex code run `node -p -e "fs.readFileSync('./cadence/contracts/FlowToken.cdc').toString('hex')"` 
4. Deploy the MetadataViews.cdc, NonFungibleToken.cdc, TradingFunctions.cdc, TradingFungiblePack.cdc, TradingNonFungibleCardGame.cdc and WitchCraftAndWizardry.cdc contracts using the VSCode extension.
5. Run the setup_admin_account.cdc Witchcraft and Wizardry transaction in order to install WnW admin resources in the ServiceAccount.
6. Now you will need to create some cards into the game, create a new set specifying it's rarities, and add cards to that set at a certain rarity. Create the cards, create the Alpha set and add those cards to it running the following transactions with Flow CLI:
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/create_cards.cdc '[{"name":"Bolt", "color": "red"},{"name":"Exile", "color": "white"},{"name":"Veil", "color": "green"},{"name": "Seize", "color": "black"},{"name": "Wave", "color": "blue"}]'`
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/create_cards.cdc '[{"name":"Crack", "color": "red"},{"name":"Harden", "color": "white"},{"name":"Grow", "color": "green"},{"name": "Kill", "color": "black"},{"name": "Counter", "color": "blue"}]'`
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/create_cards.cdc '[{"name":"Goblin", "color": "red"},{"name":"Soldier", "color": "white"},{"name":"Snake", "color": "green"},{"name": "Vampire", "color": "black"},{"name": "Spirit", "color": "blue"}]'`
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/create_set.cdc Alpha '{1:"Rare", 2: "Uncommon", 3: "Common"}'`
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/add_cards_to_set.cdc 1 '[1,2,3,4,5]' 1`
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/add_cards_to_set.cdc 1 '[6,7,8,9,10]' 2`
  - `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/add_cards_to_set.cdc 1 '[11,12,13,14,15]' 3`
7. Once the set info is ready, you can add Packs to the set. Packs get added when it's contract is deployed. Deploy WnWAlphaPacks.cdc using a transaction and passing the pack rarities distribution (how many TNFCs of each rarity is given when a pack is opened) and the price of the packs to the contract. You will need to code in hex the contract code using `node -p -e "fs.readFileSync('./cadence/contracts/WnWAlphaPacks.cdc').toString('hex')"`. Then run `flow transactions send ./cadence/transactions/WnWAlphaPacks/deploy_alpha_packs.cdc CONTRACT_HEX_CODE '{1: 1.0, 2: 2.0, 3: 3.0}' 5.0` to deploy WnW Alpha edition packs with 1 rare, 2 uncommons and 3 commons per pack, at a price of 5.0 flow tokens per pack.
8. Next, set Alpha set as currently printing running `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/start_printing_set.cdc 1`
9. Run the WnWAlphaPacks setup_admin_account.cdc transaction with VSCode to install the packSeller and the packOpener admin resources. To install the packPrinter indicating the maximum amount of packs allowed to mint run `flow transactions send ./cadence/transactions/WnWAlphaPacks/setup_pack_printer.cdc 1000` (for a thousand packs)
10. The last thing to do before users are able to buy and open packs is to print a certain amount of packs. The amount of packs printed will be the quantity of print runs indicated in the transaction times the amount of packs per printing. The amount of packs per printing is calculated by the contracts, and is the lower amount of packs that allows to print the same amount of cards of each rarity and get all of them distributed in the printed packs. When the transaction is runned, the packs are allowed to be minted in the Fungible Token contract and the necessary TNFCs for fulfiling the packs are minted in the Non-Fungible Token contract. For WnW Alpha set and WnW Alpha Packs (packs with different rarities distribution will have different print run size) the amount of packs per printing is 5, meaning in each print run 5 rares (one TNFC of each rare in set), 10 uncommon (2 TNFC of each) and 15 uncommon (3 TNFC of each) are created. Since we are creating a bunch of NFTs in just one transaction usually the gas limit has to be increased. You can do one print runexecuting the following: `flow transactions send ./cadence/transactions/WnWAlphaPacks/print_run_packs.cdc 1 --gas-limit 2000`. 
11. Finally, switch the emulator account to Alice (or any other than ServiceAccount) and run the setup_account.cdc transaction from FlowToken, WitchcraftAndWizardry and WnWAlphaPacks folder in order to get user account ready to buy and open packs.
12. Mint flow tokens into the user vault using the Flow CLI and ServiceAccount `flow transactions send ./cadence/transactions/flow/mint_tokens.cdc USER_ADDRESS 1000.0`
13. Using the VSCode extension and the choosen user account run the buy_pack.cdc and open_pack.cdc transactions in order to buy and open packs.
14. The open_pack.cdc transaction keeps the TNFCs selected for fulfiling the packs into the WnW account, so the result of the random selecction isn't known by the user until the transaction it's finished. To actually get the TNFCs into the buyers collection you need to run `flow transactions send ./cadence/transactions/WitchcraftAndWizardry/retrieve_account_cards.cdc USER_ADDRESS`. This will put all the TNFCs for opened but unretrieved packs into the owner Collection. By separating the random generation tx and the transaction where the user actually get to know about which random TNFCs got selected we avoid that malicius users check for the random selected cards and abort the transaction if they don't like the result.
15. You can check the state using the following scripts:
  - Get the printed but not yet opened NFTs IDs from the account owning WnW `flow scripts execute ./cadence/scripts/WitchcraftAndWizardry/get_printed_tnfc_ids.cdc`
  - Borrow TNFC info from the pool of unopened tnfcs `flow scripts execute ./cadence/scripts/WitchcraftAndWizardry/borrow_tnfc_admin.cdc TNFC_ID`
  (this two scripts include the admin account address hardcoded by the moment)
  - Get the info of all the TNFCs owned by a user  `flow scripts execute ./cadence/scripts/WitchcraftAndWizardry/borrow_tnfc_collection.cdc USER_ADDRESS`
16. Mess arround and let me know what can be improved!