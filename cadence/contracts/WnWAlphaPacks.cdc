//import FungibleToken from "./FungibleToken.cdc"
//import TradingFungiblePack from "./TradingFungiblePack.cdc"
//import NonFungibleToken from "./NonFungibleToken.cdc"
//import TradingNonFungibleCardGame from "./TradingNonFungibleCardGame.cdc"
//import WnW from "./WitchcraftAndWizardry.cdc"
//import FlowToken from "./FlowToken.cdc"
//import TF from "./TradingFunctions.cdc"
import FungibleToken from 0xf8d6e0586b0a20c7
import TradingFungiblePack from 0xf8d6e0586b0a20c7
import NonFungibleToken from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7
import FlowToken from 0xf8d6e0586b0a20c7
import TF from 0xf8d6e0586b0a20c7
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

    // PacksDestroyed
    //
    // The event that is emitted when Packs are destroyed
    pub event PacksDestroyed(amount: UFix64)


    // PackSellerCreated
    //
    // The event that is emitted when a new PackSeller resource is created
    pub event PackManagerCreated()

    // PackSellerCreated
    //
    // The event that is emitted when a new PackSeller resource is created
    pub event PackSellerCreated()

    // PackOpenerCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackOpenerCreated()

    // PackPrinterCreated
    //
    // The event that is emitted when a new opener resource is created
    pub event PackPrinterCreated(allowedAmount: UInt64)

    // Total supply of Packs in existence
    pub var totalSupply: UFix64
    pub var packsToSell: UInt64
    pub var packsToOpen: UInt64

    // Id from the set the packs belongs to
    pub let setID: UInt32

    pub let TFPackInfo: {TradingFungiblePack.PackInfo}

    // Named paths
    //
    pub let VaultStoragePath: StoragePath
    pub let ReceiverPrivatePath: PrivatePath
    pub let ReceiverPublicPath: PublicPath
    pub let ProviderPrivatePath: PrivatePath
    pub let BalancePublicPath: PublicPath
    pub let AdminStoragePath: StoragePath
    pub let PackPrinterStoragePath: StoragePath
    pub let PackPrinterPrivatePath: PrivatePath
    pub let PackSellerStoragePath: StoragePath
    pub let PackSellerPublicPath: PublicPath
    pub let PackOpenerStoragePath: StoragePath
    pub let PackOpenerPublicPath: PublicPath

    
    pub struct AlphaPackInfo: TradingFungiblePack.PackInfo{

        pub let packID: UInt8
        pub let packRaritiesDistribution: {UInt8: UFix64}
        pub let printingPacksAmount: UInt64
        pub let printingRaritiesSheetsQuantities: {UInt8: UInt64}
        pub let price: UFix64

        init(setID: UInt32, packRaritiesDistribution: {UInt8: UFix64}, price: UFix64){
            pre{
                //set exists? no hace falta x el panic siguiente
                //lo que si hace puta falta es que pete si no hay cartas!!!!

                //Hay que explicar muchisimas cosas, lo de calcular el printingSize y lo de calcular el sheetsPrinting size...
                // explicadas en los panic????
            }
            let setData = WnW.getSetData(setID: setID) ?? panic ("Set does not exists")
            self.packID = setData.nextPackID
            self.packRaritiesDistribution = packRaritiesDistribution
            let SetRaritiesDistribution = setData.getRaritiesDistribution() ?? panic ("Set has no cards on it yet")
            let setMinimun = TF.getNumbersDictionaryMinimun(SetRaritiesDistribution)
            let packMinimun = TF.getNumbersDictionaryMinimun(packRaritiesDistribution)
            let printingSize = setMinimun / packMinimun
            TF.isNumberInteger(printingSize) ?? panic("The number of rarest cards must be divisible by its pack's apperance")
            self.printingPacksAmount = UInt64(printingSize)
            self.printingRaritiesSheetsQuantities = {}
            for rarity in packRaritiesDistribution.keys{
                let setMinimun = TF.getNumbersDictionaryMinimun(WnW.getSetRaritiesDistribution(setID)!)
                let packMinimun = TF.getNumbersDictionaryMinimun(packRaritiesDistribution)
                let sheetsPrintingSize =  ( UFix64(setMinimun) * packRaritiesDistribution[rarity]! ) /
                                            ( UFix64(packMinimun) * setData.getRaritiesDistribution()![rarity]! )
                TF.isNumberInteger(printingSize) ?? panic("Bad pack rarity distribution for the set rarity distribution. See TNFCG Game Designer Help")
                self.printingRaritiesSheetsQuantities[rarity] = 1
            }
            self.price = price
        }
    }

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
                emit PacksDestroyed(amount: self.balance)
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



        // createNewPackCrafter
        //
        // Function that creates and returns a new PackOpener resource
        //
        pub fun createNewPackPrinter(allowedAmount: UInt64, printRunnerCapability: Capability<&WnW.SetPrintRunner>): @PackPrinter {
            emit PackPrinterCreated(allowedAmount: allowedAmount)
            return <- create PackPrinter(allowedAmount: allowedAmount, printRunnerCapability: printRunnerCapability)
        }

        // createNewPackSeller
        //
        // Function that creates and returns a new PackSeller resource
        //
        pub fun createNewPackSeller(packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>): @PackSeller {
            emit PackSellerCreated()
            return <- create PackSeller(packSellerFlowTokenCapability: packSellerFlowTokenCapability)
        }

        // createNewPackOpener
        //
        // Function that creates and returns a new PackOpener resource
        //
        pub fun createNewPackOpener(packFulfilerCapability: Capability<&WnW.SetPackFulfiler>): @PackOpener {
            emit PackOpenerCreated()
            return <- create PackOpener(packFulfilerCapability: packFulfilerCapability)
        }


    }


    pub resource PackPrinter: TradingFungiblePack.PackPrinter{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let printRunnerCapability: Capability<&WnW.SetPrintRunner>

        // The remaining amount of Packs that the PackManager is allowed to mint
        pub var allowedAmount: UInt64
        // printRun creates in the TNFCG contract the necessary amount of NFTs
        // to fulfil the pack amount equal to the printRun times the printed print runs quantity
        pub fun printRun(quantity: UInt64): UInt64{
            
            // Creates and stores the necessary NFTs in the contract's collection por the desired quantity of printings
            self.printRunnerCapability.borrow()!.printRun(setID: WnWAlphaPacks.setID, packID: WnWAlphaPacks.TFPackInfo.packID, quantity: quantity)
 
            // the total amount of packs created for the desireds print runs
            let packsPrintedAmount = WnWAlphaPacks.TFPackInfo.printingPacksAmount * quantity
            // decrease the amount of packs the printer is allowed to create
            self.allowedAmount = self.allowedAmount - packsPrintedAmount
            // increase the amount of packs that are available to sell
            WnWAlphaPacks.packsToSell = WnWAlphaPacks.packsToSell + packsPrintedAmount
            return packsPrintedAmount
        }

        init(allowedAmount: UInt64, printRunnerCapability: Capability<&WnW.SetPrintRunner>){
            self.allowedAmount = allowedAmount
            self.printRunnerCapability = printRunnerCapability
        }
    }

    pub resource PackSeller: TradingFungiblePack.PackSeller{
        // A capability allowing this resource to deposit the Flow tokens given as payment
        access(contract) let packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>

        // sellPacks
        //
        // Function that sells new Packs, adds them to the total supply,
        // and returns them to the calling context.
        //
        pub fun sellPacks(payment: @FungibleToken.Vault, packsPayerPackReceiver: &{FungibleToken.Receiver}, amount: UFix64) {
            pre {
                payment.isInstance(Type<@FlowToken.Vault>()): "Payment must be done in Flow tokens"
                packsPayerPackReceiver.isInstance(Type<@WnWAlphaPacks.Vault>()): "This only sells WnW Alpha Packs"
                UInt64(amount) <= WnWAlphaPacks.packsToSell: "Amount minted must be less than the allowed amount of printed packs remaining"
                payment.balance >= amount * WnWAlphaPacks.TFPackInfo.price: "Payment is not enought for the desired pack amount"
            }
            //deposit the payment in the packs seller's account
            self.packSellerFlowTokenCapability.borrow()!.deposit(from: <- payment.withdraw(amount:amount * WnWAlphaPacks.TFPackInfo.price))
            destroy payment
            //increase the totalSupply
            WnWAlphaPacks.totalSupply = WnWAlphaPacks.totalSupply + amount
            WnWAlphaPacks.packsToSell = WnWAlphaPacks.packsToSell - UInt64(amount)
            WnWAlphaPacks.packsToOpen = WnWAlphaPacks.packsToOpen + UInt64(amount)
            emit PacksSelled(amount: amount)
            packsPayerPackReceiver.deposit(from: <- create Vault(balance: amount))
        }
        
        init (packSellerFlowTokenCapability: Capability<&{FungibleToken.Receiver}>) {
            self.packSellerFlowTokenCapability = packSellerFlowTokenCapability
        }

    }

    pub resource PackOpener: TradingFungiblePack.PackOpener{
        // A capability allowing this resource to withdraw the NFT with the given ID from its collection.
        // This capability allows the resource to withdraw *any* NFT, so you should be careful when giving
        // such a capability to a resource and always check its code to make sure it will use it in the
        // way that it claims.
        access(contract) let packFulfilerCapability: Capability<&WnW.SetPackFulfiler>
        
        // openPacks
        //
        // Function for destroying packs
        //
        pub fun openPacks(packsToOpen: @FungibleToken.Vault, packsOwnerCardCollectionPublic: &{NonFungibleToken.CollectionPublic}){
            pre {
                packsToOpen.isInstance(Type<@WnWAlphaPacks.Vault>()): "Tokens must be WnW Alpha edition packs"
                packsOwnerCardCollectionPublic.isInstance(Type<@WnW.Collection>()): "Reciving collection must belong to WnW"
                UInt64(packsToOpen.balance) <= WnWAlphaPacks.packsToOpen: "Amount opened must be less than the remaining amount of unopened packs"
            }
            self.packFulfilerCapability.borrow()!.fulfilPacks(setID: WnWAlphaPacks.setID, packID: WnWAlphaPacks.TFPackInfo.packID, amount: packsToOpen.balance, packsOwnerCardCollectionPublic: packsOwnerCardCollectionPublic)
            emit PacksDestroyed(amount: packsToOpen.balance)
            WnWAlphaPacks.packsToOpen = WnWAlphaPacks.packsToOpen - UInt64(packsToOpen.balance)
            destroy packsToOpen
        }

        init (packFulfilerCapability: Capability<&WnW.SetPackFulfiler>) {
            self.packFulfilerCapability = packFulfilerCapability
        }
    }


    init(setID: UInt32, packRaritiesDistribution: {UInt8: UFix64}, price: UFix64, setManagerCapability: Capability<&{TradingNonFungibleCardGame.SetManager}>) {
        // Initialize contract state.
        //
        self.totalSupply = 0.0
        self.packsToSell = 0
        self.packsToOpen = 0
        self.setID = setID
        self.TFPackInfo = AlphaPackInfo(setID: setID, packRaritiesDistribution: packRaritiesDistribution, price: price)
        // add Pack Info to the set
        let SetManagerRef = setManagerCapability.borrow() ?? panic("Set manager not found")
        log("Se va a añadir el pack info al set ")
        log(setID)
        SetManagerRef.addPackInfo(setID: setID, packInfo: self.TFPackInfo)
        log(self.TFPackInfo.packID)
        log(self.TFPackInfo.printingPacksAmount)
        log(self.TFPackInfo.price)
        self.VaultStoragePath = /storage/WnWAlphaPacksVault
        self.ReceiverPublicPath = /public/WnWAlphaPacksVault
        self.ReceiverPrivatePath = /private/WnWAlphaPacksVault
        self.ProviderPrivatePath = /private/WnWAlphaPacksVault
        self.BalancePublicPath = /public/WnWAlphaPacksBalance
        // path para guardar el recurso Admin (se guarda aqui en init)
        self.AdminStoragePath = /storage/WnWAlphaPacksAdmin
        self.PackSellerStoragePath = /storage/WnWAlphaPackSeller
        // path para la capability del pack seller
        self.PackSellerPublicPath = /public/WnWAlphaPackSeller
        self.PackOpenerStoragePath = /storage/WnWAlphaPackOpener
        // path pa la capability del opener
        self.PackOpenerPublicPath = /public/WnWAlphaPackOpener
        // 
        self.PackPrinterStoragePath = /storage/WnWAlphaPackPrinter
        self.PackPrinterPrivatePath = /private/WnWAlphaPackPrinter


        // Create the one true Admin object and deposit it into the contract account.
        // este recurso es el que puede vender y abrir packs
        // recibe y guarda la capability para recibir tokens de flow (para recibir los pagos de la venta de sobres)
        // y la capability para fulfil sobres de WnW para enviar las NFCards
        //
        self.account.save(<-create Administrator(), to: self.AdminStoragePath)



        // Emit an event that shows that the contract was initialized.
        emit TokensInitialized(initialSupply: self.totalSupply)
    
    }
}
 