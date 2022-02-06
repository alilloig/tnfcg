import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import WnW from "../../contracts/Witchcraft&Wizardry.cdc"
//import NonFungibleToken from 0xf8d6e0586b0a20c7
//import WnW from 0xf8d6e0586b0a20c7

// This transction uses the NFTMinter resource to mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(recipient: Address, typeID: UInt8) {
    //esta transaccion emberda tiene que ser la que reciba sobres de recipient y devuelva cartas

    // local variable for storing the minter reference
    let minter: &WnW.NFTMinter

    prepare(signer: AuthAccount) {

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&WnW.NFTMinter>(from: WnW.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        // get the public account object for the recipient
        let recipient = getAccount(recipient)

        // borrow the recipient's public NFT collection reference
        let receiver = recipient
            .getCapability(WnW.PrintedCardsPublicPath)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // mint the NFT and deposit it to the recipient's collection
        //esto en vez de mintNFT tiene que ser crackPacks? devuelve un diccionario de nfts?
        self.minter.mintNFT(recipient: receiver, typeID: typeID)
    }
}
