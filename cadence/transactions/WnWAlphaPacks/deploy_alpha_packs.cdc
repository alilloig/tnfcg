import FungibleToken from 0xf8d6e0586b0a20c7
import TradingNonFungibleCardGame from 0xf8d6e0586b0a20c7
import WnW from 0xf8d6e0586b0a20c7
//import FungibleToken from "../../contracts/FungibleToken.cdc"
//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"

transaction(contract: String, packRaritiesDistribution: {UInt8: UFix64}, price: UFix64) {
    
    prepare(signer: AuthAccount) {
        signer.contracts.add(name: "WnWAlphaPacks", 
                            code: contract.decodeHex(),
                            setID: UInt32(1),
                            packRaritiesDistribution: packRaritiesDistribution,
                            price: price,
                            setManagerCapability: signer.getCapability<&{TradingNonFungibleCardGame.SetManager}>(WnW.SetManagerPrivatePath)
                          )

    }

}