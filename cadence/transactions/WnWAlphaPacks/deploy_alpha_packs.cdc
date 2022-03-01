//import FungibleToken from 0xf8d6e0586b0a20c7
//import FungiblePack from 0xf8d6e0586b0a20c7
//import WnWAlphaPacks from 0xf8d6e0586b0a20c7
import FungibleToken from "../../contracts/FungibleToken.cdc"
import TradingFungiblePack from "../../contracts/TradingFungiblePack.cdc"
import WnW from "../../contracts/WitchcraftAndWizardry.cdc"

transaction(setID: UInt32, packRaritiesDistribution: {UInt8: UFix64}, price: UFix64) {
    
    prepare(signer: AuthAccount) {    
        // `code` has type `[UInt8]`
        let code = "../../contracts/WnWAlphaPacks.cdc".decodeHex()
        
        signer.contracts.add(name: "WnWAlphaPacks", 
                            code: code,
                            setID: WnW.nextSetID,
                            packRaritiesDistribution: packRaritiesDistribution,
                            price: price,
                            setManagerCapability: signer.getCapability<&WnW.SetManager>(WnW.SetManagerPrivatePath)
                          )

    }
}