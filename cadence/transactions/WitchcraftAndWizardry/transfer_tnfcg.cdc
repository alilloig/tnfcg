import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// This transaction transfers a Kitty Item from one account to another.

transaction(recipient: Address, withdrawID: UInt64) {
    prepare(signer: AuthAccount) {
        
        // get the recipients public account object
        let recipient = getAccount(recipient)

        // borrow a reference to the signer's NFT collection
        let collectionRef = signer.borrow<&WnW.Collection>(from: WnW.PrintedCardsStoragePath)
            ?? panic("Could not borrow a reference to the owner's collection")

        // borrow a public reference to the receivers collection
        let depositRef = recipient.getCapability(WnW.PrintedCardsPublicPath)!.borrow<&{NonFungibleToken.CollectionPublic}>()!

        // withdraw the NFT from the owner's collection
        let nft <- collectionRef.withdraw(withdrawID: withdrawID)

        // Deposit the NFT in the recipient's collection
        depositRef.deposit(token: <-nft)
    }
}

