import FungibleToken from "./FungibleToken.cdc"
import TradingFungiblePack from "./TradingFungiblePack.cdc"
import NonFungibleToken from "./NonFungibleToken.cdc"
import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
import WnW from "./WitchcraftAndWizardry.cdc"
import FlowToken from "./FlowToken.cdc"
//import FungibleToken from 0xf8d6e0586b0a20c7
//import TradingFungiblePack from 0xf8d6e0586b0a20c7
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7
//import FlowToken from 0xf8d6e0586b0a20c7

/**

## The Flow Trading Non-Fungible Card Pack standard

## `Pack` resource

The core resource type that represents a Pack in the smart contract.

## `Vault` resource

Each account that owns set packs would need to have an instance
of the Vault resource stored in their account storage.

The Vault resource has methods that the owner and other users can call.

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

pub contract WnWAlphaPacks: FungibleToken, TradingFungiblePack{

    // Total supply of Packs in existence
    pub var totalSupply: UFix64

    // Id from the set the packs belongs to
    pub let setID: UInt32

    // Id of the pack in the set
    pub let packID: UInt8

    pub let TFPackInfo: {TradingNonFungibleCardGame.PackInfo}

    pub struct WnWAlphaPacksInfo: TradingNonFungibleCardGame.PackInfo{
        pub let packID: UInt8
        pub let setID: UInt32
        pub let packRarities: {UInt8: String}
        pub let packRaritiesDistribution: {UInt8: UInt}
        pub let packPrintingSize: UInt
        init(packID: UInt8, setID: UInt32, packRarities: {UInt8: String}, packRarityDistribution: {UInt8: UInt}){
            self.packID = packID
            self.setID = setID
            self.packRarities = packRarities
            self.packRaritiesDistribution = packRarityDistribution
            var size = self.packRaritiesDistribution[self.packRarities.keys[0]]!
            for rarityID in packRarities.keys{
                //self.packRarityProbability[rarityID] = 
                    //self.packRarityDistribution[rarityID] / 3.0//WnW.getSetRarityDistribution(setID: setID, rarityID: rarityID)
                if (self.packRaritiesDistribution[rarityID]! < size){
                    size = self.packRaritiesDistribution[rarityID]!
                }
            }
            self.packPrintingSize = size
        }
    }

    // TokensInitialized
    //
    // The event that is emitted when the contract is created
    pub event TokensInitialized(initialSupply: UFix64)

    // TokensWithdrawn
    //
    // The event that is emitted when Packs are withdrawn from a Vault
    pub event TokensWithdrawn(amount: UFix64, from: Address?)

    // TokensDeposited
    //
    // The event that is emitted when Packs are deposited to a Vault
    pub event TokensDeposited(amount: UFix64, to: Address?)

    // PacksSelled
    //
    // The event that is emitted when new Packs are selled
    pub event PacksSelled(amount: UFix64)

    // PacksOpened
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksOpened(amount: UFix64)

    // PackSellerCreated
    //
    // The event that is emitted when a new PackSeller resource is created
    pub event PackSellerCreated(allowedAmount: UFix64)

    // PackOpenerCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackOpenerCreated(allowedAmount: UFix64)

    // Named paths
    //
    pub let VaultStoragePath: StoragePath
    pub let ReceiverPublicPath: PublicPath
    pub let BalancePublicPath: PublicPath
    pub let AdminStoragePath: StoragePath
    pub let PackSellerStoragePath: StoragePath
    pub let PackSellerPublicPath: PublicPath
    pub let PackOpenerStoragePath: StoragePath
    pub let PackOpenerPublicPath: PublicPath

    // Vault
    //
    // Each user stores an instance of only the Vault in their storage
    // The functions in the Vault and governed by the pre and post conditions
    // in FungibleToken when they are called.
    // The checks happen at runtime whenever a function is called.
    //
    // Resources can only be created in the context of the contract that they
    // are defined in, so there is no way for a malicious user to create Vaults
    // out of thin air. A special PackMinter resource needs to be defined to mint
    // new Packs.
    //
    pub resource Vault: FungibleToken.Provider, FungibleToken.Receiver, FungibleToken.Balance {

        // The total balance of this vault
        pub var balance: UFix64

        // initialize the balance at resource creation time
        init(balance: UFix64) {
            self.balance = balance
        }

        // withdraw
        //
        // Function that takes an amount as an argument
        // and withdraws that amount from the Vault.
        //
        // It creates a new temporary Vault that is used to hold
        // the money that is being transferred. It returns the newly
        // created Vault to the context that called so it can be deposited
        // elsewhere.
        //
        pub fun withdraw(amount: UFix64): @FungibleToken.Vault {
            pre{
                //do we really want this??
                amount % 1.0 == 0.0: "You cannot withdraw fractions of packs"
            }
            self.balance = self.balance - amount
            emit TokensWithdrawn(amount: amount, from: self.owner?.address)
            return <-create Vault(balance: amount)
        }

        // deposit
        //
        // Function that takes a Vault object as an argument and adds
        // its balance to the balance of the owners Vault.
        //
        // It is allowed to destroy the sent Vault because the Vault
        // was a temporary holder of the Packs. The Vault's balance has
        // been consumed and therefore can be destroyed.
        //
        pub fun deposit(from: @FungibleToken.Vault) {
            pre{
                //do we really want this??
                from.balance % 1.0 == 0.0: "You cannot deposit fractions of packs"
            }
            let vault <- from as! @WnWAlphaPacks.Vault
            self.balance = self.balance + vault.balance
            emit TokensDeposited(amount: vault.balance, to: self.owner?.address)
            vault.balance = 0.0
            destroy vault
        }

        destroy() {
            WnWAlphaPacks.totalSupply = WnWAlphaPacks.totalSupply - self.balance
            if(self.balance > 0.0) {
                emit PacksOpened(amount: self.balance)
            }
        }
    }

    // createEmptyVault
    //
    // Function that creates a new Vault with a balance of zero
    // and returns it to the calling context. A user must call this function
    // and store the returned Vault in their storage in order to allow their
    // account to be able to receive deposits of this Pack type.
    //
    pub fun createEmptyVault(): @Vault {
        return <-create Vault(balance: 0.0)
    }

    pub resource Administrator{
        
        // createNewPackSeller
        //
        // Function that creates and returns a new PackSeller resource
        //
        pub fun createNewPackSeller(packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>): @PackSeller {
            emit PackSellerCreated(allowedAmount: 0.0)
            return <- create PackSeller(packSellerFlowTokenCapability: packSellerFlowTokenCapability)
        }

        // createNewPackOpener
        //
        // Function that creates and returns a new PackOpener resource
        //
        pub fun createNewPackOpener(packFulfilerCapability: Capability<&{TradingNonFungibleCardGame.SetPackFulfiler}>): @PackOpener {
            emit PackOpenerCreated(allowedAmount: 0.0)
            return <- create PackOpener(packFulfilerCapability: packFulfilerCapability)
        }
    }

    pub resource PackSeller: TradingFungiblePack.PackSeller{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>

        // The amount of Packs that the PackMinter is allowed to mint
        pub var allowedAmount: UFix64
        
        // sellPacks
        //
        // Function that sells new Packs, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun sellPacks(payment: &FungibleToken.Vault, packsPayerPackReceiver: &{FungibleToken.Receiver}, amount: UFix64) {
            pre {
                payment.isInstance(Type<@FlowToken.Vault>()): "Payment must be done in Flow tokens"
                amount <= self.allowedAmount: "Amount minted must be less than the allowed amount of printed packs remaining"
                //amount debe ser inferior al precio del sobre + amount
            }
            /*FALTA CALCULAR EL PRECIO A COBRAR!!! AMOUNT * PRECIO DE SOBRE!!! 
                empieza el movidote de definir el set incluyendo precio del sobre
            */
            self.packSellerFlowTokenCapability.borrow()!.deposit(from: <- payment.withdraw(amount: 1.0))
            WnWAlphaPacks.totalSupply = WnWAlphaPacks.totalSupply + amount
            //todo esto esta mal, hay que revisarlo y puede que caigan funciones para manipular las amounts de un recurso a otro
            self.allowedAmount = self.allowedAmount - amount
            self.allowedAmount = self.allowedAmount + amount
            emit PacksSelled(amount: amount)
            packsPayerPackReceiver.deposit(from: <- create Vault(balance: amount))
        }
        
        init (packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>) {
            self.packSellerFlowTokenCapability = packSellerFlowTokenCapability
            self.allowedAmount = 0.0
        }

    }

    pub resource PackOpener: TradingFungiblePack.PackOpener{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let packFulfilerCapability: Capability<&{TradingNonFungibleCardGame.SetPackFulfiler}>

        // The amount of Packs that the PackOpener is allowed to open
        pub var allowedAmount: UFix64
        
        // openPacks
        //
        // Function for destroying packs
        //
        pub fun openPacks(packsToOpen: &FungibleToken.Vault, packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic}){
            pre {
                packsToOpen.isInstance(Type<@WnWAlphaPacks.Vault>()): "Tokens must be WnW Alpha edition packs"
                packsOwnerCardCollectionPublic.isInstance(Type<@WnW.Collection>()): "Reciving collection must belong to WnW"
                packsToOpen.balance <= self.allowedAmount: "Amount opened must be less than the remaining amount of unopened packs"
            }
            let openedPacks <- packsToOpen.withdraw(amount: packsToOpen.balance)
            WnWAlphaPacks.totalSupply = WnWAlphaPacks.totalSupply - openedPacks.balance
            self.allowedAmount = self.allowedAmount - openedPacks.balance
            self.packFulfilerCapability.borrow()!.fulfilPacks(setID: WnWAlphaPacks.setID, packID: WnWAlphaPacks.packID, amount: openedPacks.balance, packsOwnerCardCollectionPublic: packsOwnerCardCollectionPublic)
            emit PacksOpened(amount: openedPacks.balance)
            destroy openedPacks
        }

        init (packFulfilerCapability: Capability<&{TradingNonFungibleCardGame.SetPackFulfiler}>) {
            self.packFulfilerCapability = packFulfilerCapability
            self.allowedAmount = 0.0
        
        }
    }


    init(packID: UInt8, setID: UInt32, packRarities: {UInt8: String}, packRarityDistribution: {UInt8: UInt}) {
        pre{
            // checks that there is a flow token receiver on the account
            self.account.getCapability<&FlowToken.Vault{FungibleToken.Receiver}>(/public/flowTokenReceiver).check<>(): "Account cannot receive flow tokens"
            // si cambiamos WnW para usar self.account habrá q cambiar packfulfiler por Administrator
            self.account.getCapability<&{TradingNonFungibleCardGame.SetPackFulfiler}>(WnW.PackFulfilerPrivatePath).check<>(): "Account cannot fulfil WnW packs"
        }
        
        // Initialize contract state.
        //
        self.totalSupply = 0.0
        self.setID = setID
        self.packID = packID
        self.TFPackInfo = WnWAlphaPacksInfo(packID: packID, setID: setID, packRarities: packRarities, packRarityDistribution: packRarityDistribution)


        self.VaultStoragePath = /storage/WnWAlphaPacksVault
        self.ReceiverPublicPath = /public/WnWAlphaPacksReceiver
        self.BalancePublicPath = /public/WnWAlphaPacksBalance
        // path para guardar el recurso Admin (se guarda aqui en init)
        self.AdminStoragePath = /storage/WnWAlphaPacksAdmin
        self.PackSellerStoragePath = /storage/WnWAlphaPackSeller
        // path para la capability del pack seller
        self.PackSellerPublicPath = /public/WnWAlphaPackSeller
        self.PackOpenerStoragePath = /storage/WnWAlphaPackOpener
        // path pa la capability del opener
        self.PackOpenerPublicPath = /public/WnWAlphaPackOpener


        // Create the one true Admin object and deposit it into the contract account.
        // este recurso es el que puede vender y abrir packs
        // recibe y guarda la capability para recibir tokens de flow (para recibir los pagos de la venta de sobres)
        // y la capability para fulfil sobres de WnW para enviar las NFCards
        //
        self.account.save(<-create Administrator(), to: self.AdminStoragePath)

       /* packSellerFlowTokenCapability: self.account.getCapability<&{FungibleToken.Receiver}>(/public/flowTokenReceiver), 
                packFulfilerCapability: self.account.getCapability<&{TradingNonFungibleCardGame.PackFulfiler}>(WnW.PackFulfilerPrivatePath)
        // Expose a public capability allowing users to get packs in exchange for flow tokens
        self.account.link<&WnWAlphaPacks.Administrator{TradingFungiblePack.PackSeller}>(
            self.PackSellerPublicPath,
            target: self.AdminStoragePath
        )

        // Expose a public capability allowing users to open packs, sending it to the account and receiving WnW cards
        self.account.link<&WnWAlphaPacks.Administrator{TradingFungiblePack.PackOpener}>(
            self.PackOpenerPublicPath,
            target: self.AdminStoragePath
        ) */

        // Emit an event that shows that the contract was initialized.
        emit TokensInitialized(initialSupply: self.totalSupply)
    
    }
}
 