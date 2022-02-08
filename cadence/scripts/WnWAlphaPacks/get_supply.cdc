//import TNFCGAlphaPacks from "../../contracts/TNFCGAlphaPacks.cdc"
import TNFCGAlphaPacks from 0xf8d6e0586b0a20c7

// This script returns the total amount of packs currently in existence.

pub fun main(): UInt256 {
    let supply = TNFCGAlphaPacks.totalSupply
    log(supply)
    return supply
}
