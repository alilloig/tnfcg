import NonFungibleToken from "../../contracts/NonFungibleToken.cdc"
import TNFCGCards from "../../contracts/TNFCGCards.cdc"

// This transction uses the NFTMinter resource to mint a new NFT.
//
// It must be run with the account that has the minter resource
// stored at path /storage/NFTMinter.

transaction(recipient: Address, typeID: UInt64, setCards: {UInt16: {UInt8: TNFCGCards.CardInfo}}) {
    //esta transaccion emberda tiene que ser la que reciba sobres de recipient y devuelva cartas

    // local variable for storing the minter reference
    let minter: &TNFCGCards.NFTMinter

    prepare(signer: AuthAccount) {

        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&TNFCGCards.NFTMinter>(from: TNFCGCards.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        // get the public account object for the recipient
/*         let recipient = getAccount(recipient)

        // borrow the recipient's public NFT collection reference
        let receiver = recipient
            .getCapability(TNFCGCards.PrintedCardsPublicPath)!
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection") */

        // mint the NFT and deposit it to the recipient's collection
        //esto en vez de mintNFT tiene que ser crackPacks? devuelve un diccionario de nfts?
        self.minter.mintNFT(recipient: receiver, typeID: typeID)
    }
}