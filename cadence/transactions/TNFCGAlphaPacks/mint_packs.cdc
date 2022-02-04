import FungiblePack from 0xf8d6e0586b0a20c7//"../../contracts/FungiblePack.cdc"
import TNFCGAlphaPacks from 0xf8d6e0586b0a20c7//"../../contracts/TNFCGAlphaPacks.cdc"

transaction(recipient: Address, amount: UInt256) {
    let packsAdmin: &TNFCGAlphaPacks.Administrator
    let packsReceiver: &{FungiblePack.Receiver}

    prepare(signer: AuthAccount) {
        
        //mete en PackAdmin de la tx una capability de admin que este en signer, esta capability solo la tiene la cuenta que inicializo el contrato asi q si no panic
        self.packsAdmin = signer.borrow<&TNFCGAlphaPacks.Administrator>(from: TNFCGAlphaPacks.AdminStoragePath)
            ?? panic("Signer is not the packs admin")

        //y con esto sacamos el recibidor de sobres del q los compra, o k
        //y aqui mete en PackReceiver de la tx lacapability de recibir sobres del recipient
        self.packsReceiver = getAccount(recipient)
        .getCapability(TNFCGAlphaPacks.ReceiverPublicPath)!
        .borrow<&{FungiblePack.Receiver}>()
        ?? panic("Unable to borrow receiver reference")
    }

    execute {
        
        let minter <- self.packsAdmin.createNewPackMinter(allowedAmount: amount)
        let mintedVault <- minter.mintPacks(amount: amount)

        self.packsReceiver.deposit(from: <-mintedVault)

        destroy minter
    }
}
 