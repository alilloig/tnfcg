# Witchcraft And Wizardry
## A Trading Non-Fungible Card Game

This repository contains the smart contracts and transactions that implement the core functionality of Witchcraft And Wizardry, a learning cadence project emulating a Trading Card Game with NFTs, featuring random on-chain packs, implemented as FTs, as the only way to distribute said NFTs.

### What is WnW?



## Contract Interfaces

The functionalities of the TNFCGs are defined through the 'TradingNonFungibleCardGame.cdc' contract interface
### TradingNonFungibleCardGame.cdc

WnW (or any other possible TNFCG) conforms to the NonTokenFungible.cdc interface and to the TradingNonFungibleCardGame.cdc interface
- A TNFCG can have any number of cards. Trading Non-Fungible Cards are NFTs copies of those cards.
- A TNFCG is made up of any number of sets. A set include any number of cards each of them at a certain rarity.
- Each set must have at least one type of pack. The pack contains a certain amount of TNFC of any of the set's rartities. 

### TradingFungiblePack.cdc

WnW Alpha Edition Packs (or any other TNFCG pack) conforms to the FungibleToken.cdc interface and to the TradingFungiblePack.cdc interface.
Packs are Fungible Tokens that can be purchased in exchange to another FT from the contract. Alpha packs can be purchased using Flow Tokens. Packs can be traded as any other fungible token, or can be opened, wich means been send to the TradingFungiblePack contract, which will destroy those tokens and deposit the opened NFTs in the seller's collection.

- When the pack contract is deployed, it's information is added to the set to which it belongs.
- The pack's administrator resource can create 3 resources to manage the lyfe-cicle of the packs and 





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
14. You can check the state using the following scripts:
  - Get the printed but not yet opened NFTs IDs from the account owning WnW `flow scripts execute ./cadence/scripts/WitchcraftAndWizardry/get_printed_tnfc_ids.cdc`
  - Borrow TNFC info from the pool of unopened tnfcs `flow scripts execute ./cadence/scripts/WitchcraftAndWizardry/borrow_tnfc_admin.cdc TNFC_ID`
  (this two scripts include the admin account address hardcoded by the moment)
  - Get the info of all the TNFCs owned by a user  `flow scripts execute ./cadence/scripts/WitchcraftAndWizardry/borrow_tnfc_collection.cdc USER_ADDRESS`
15. Mess arround and let me know what can be improved!