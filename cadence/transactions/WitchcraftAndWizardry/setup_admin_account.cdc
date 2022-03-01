import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import TradingNonFungibleCardGame from "../../contracts/TradingNonFungibleCardGame.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// This transaction configures an account to hold Kitty Items.

transaction {

    let wnwAdmin: &WnW.Administrator

    prepare(signer: AuthAccount) {
        
        // Check if the signer is the WnW Admin
        self.wnwAdmin = signer.borrow<&WnW.Administrator>(from: WnW.AdminStoragePath)
            ?? panic("Signer is not the WnW admin")

        // if the account doesn't already have a collection
        if signer.borrow<&WnW.Collection>(from: WnW.OwnedCardsStoragePath) == nil {
            // save it to the account
            signer.save(<- WnW.createEmptyCollection(), to: WnW.OwnedCardsStoragePath)

            // create a private receiver capability for the collection
            signer.link<&WnW.Collection{NonFungibleToken.Receiver}>(WnW.PrintedCardsPrivateReceiverPath, target: WnW.OwnedCardsStoragePath)
            
            // create a private capability for extracting the cards from the printed collection
            signer.link<&WnW.Collection{NonFungibleToken.Provider}>(WnW.PrintedCardsPrivateProviderPath, target: WnW.OwnedCardsStoragePath)
        
        
        }

        //if the account doesn't already have a CardCreator
        if signer.borrow<&WnW.CardCreator{TradingNonFungibleCardGame.CardCreator}>(from: WnW.CardCreatorStoragePath) == nil{
            signer.save(
                <- self.wnwAdmin.createNewCardCreator(), to: WnW.CardCreatorStoragePath)
            // expose a private capability to the CardCreator
            signer.link<&{TradingNonFungibleCardGame.CardCreator}>(WnW.CardCreatorPrivatePath, target: WnW.CardCreatorStoragePath)
        }      

        //if the account doesn't already have a SetManager
        if signer.borrow<&WnW.SetManager{TradingNonFungibleCardGame.SetManager}>(from: WnW.SetManagerStoragePath) == nil{
            signer.save(
                <- self.wnwAdmin.createNewSetManager(), to: WnW.SetManagerStoragePath)
            // expose a private capability to the SetManager
            signer.link<&{TradingNonFungibleCardGame.SetManager}>(WnW.SetManagerPrivatePath, target: WnW.SetManagerStoragePath)
        }      

        //if the account doesn't already have a SetPrintRunner
        if signer.borrow<&WnW.SetPrintRunner{TradingNonFungibleCardGame.SetPrintRunner}>(from: WnW.SetPrintRunnerStoragePath) == nil{
            signer.save(
                <- self.wnwAdmin.createNewSetPrintRunner(
                        printedCardsCollectionPrivateReceiver: signer.getCapability<&{NonFungibleToken.Receiver}>(WnW.PrintedCardsPrivateReceiverPath)), 
                to: WnW.SetPrintRunnerStoragePath)
            // expose a private capability to the pack fulfiler
            signer.link<&{TradingNonFungibleCardGame.SetPrintRunner}>(WnW.SetPrintRunnerPrivatePath, target: WnW.SetPrintRunnerStoragePath)
        }      

        //if the account doesn't already have a Setpackfulfiler
        if signer.borrow<&WnW.SetPackFulfiler{TradingNonFungibleCardGame.SetPackFulfiler}>(from: WnW.SetPackFulfilerStoragePath) == nil{
            signer.save(
                <- self.wnwAdmin.createNewSetPackFulfiler(
                        printedCardsCollectionPrivateProvider: signer.getCapability<&{NonFungibleToken.Provider}>(WnW.PrintedCardsPrivateProviderPath)), 
                to: WnW.SetPackFulfilerStoragePath)
            // expose a private capability to the pack fulfiler
            signer.link<&{TradingNonFungibleCardGame.SetPackFulfiler}>(WnW.SetPackFulfilerPrivatePath, target: WnW.SetPackFulfilerStoragePath)
        }        
    }
}

