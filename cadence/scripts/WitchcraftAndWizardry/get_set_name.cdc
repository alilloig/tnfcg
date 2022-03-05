//import WnW from "../../contracts/WitchcraftAndWizardry.cdc"
import WnW from 0xf8d6e0586b0a20c7

// This scripts returns the number of TNFCGCards currently in existence.

pub fun main(setID: UInt32): String {    
    let setData = WnW.getSetData(setID: setID) ?? panic ("Set does not exists")
    return setData.name
}
