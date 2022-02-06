//import FungibleToken from 0xf8d6e0586b0a20c7
//import FungiblePack from 0xf8d6e0586b0a20c7
//import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import FungibleToken from "../../contracts/FungibleToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import WnWAlphaPacks from "../../contracts/W&WAlphaPacks.cdc"

transaction(recipient: Address, amount: UFix64) {
    let packsAdmin: &WnWAlphaPacks.SetAdministrator
    let packsReceiver: &{FungibleToken.Receiver}

    prepare(signer: AuthAccount) {
        
        //mete en PackAdmin de la tx una capability de admin que este en signer, esta capability solo la tiene la cuenta que inicializo el contrato asi q si no panic
        self.packsAdmin = signer.borrow<&WnWAlphaPacks.SetAdministrator>(from: WnWAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the packs admin")

        //y con esto sacamos el recibidor de sobres del q los compra, o k
        //y aqui mete en PackReceiver de la tx lacapability de recibir sobres del recipient
        self.packsReceiver = getAccount(recipient)
        .getCapability(WnWAlphaPacks.ReceiverPublicPath)!
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference")
    }

    execute {
        
        let minter <- self.packsAdmin.createNewPackMinter(allowedAmount: amount)
        let mintedVault <- minter.mintPacks(amount: amount)

        self.packsReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}
 