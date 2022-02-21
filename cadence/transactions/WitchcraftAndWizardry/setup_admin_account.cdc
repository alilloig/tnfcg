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
        if signer.borrow<&WnW.Collection>(from: WnW.PrintedCardsStoragePath) == nil {
            // save it to the account
            signer.save(<- WnW.createEmptyCollection(), to: WnW.PrintedCardsStoragePath)

            //hay que crear un receiver privado y una collection espesial solo para ver
            // create a public capability for the collection
            signer.link<&WnW.Collection{NonFungibleToken.CollectionPublic, WnW.WnWCollectionPublic}>(WnW.PrintedCardsPublicPath, target: WnW.PrintedCardsStoragePath)
            
            // create a private capability for extracting the cards from the printed collection
            signer.link<&WnW.Collection{NonFungibleToken.Provider}>(WnW.PrintedCardsPrivatePath, target: WnW.PrintedCardsStoragePath)
        }

        //if the account doesn't already have a packfulfiler
        if signer.borrow<&WnW.PackFulfiler{TradingNonFungibleCardGame.PackFulfiler}>(from: WnW.PackFulfilerStoragePath) == nil{
            signer.save(
                <- self.wnwAdmin.createNewPackFulfiler(
                        printedCardsCollectionProviderCapability: signer.getCapability<&{NonFungibleToken.Provider, WnW.WnWCollectionPublic}>(WnW.PrintedCardsPrivatePath), allowedAmount: 100.0), 
                to: WnW.PackFulfilerStoragePath)
            // expose a private capability to the pack fulfiler
            signer.link<&{TradingNonFungibleCardGame.PackFulfiler}>(WnW.PackFulfilerPrivatePath, target: WnW.PackFulfilerStoragePath)
        }
    }
}

